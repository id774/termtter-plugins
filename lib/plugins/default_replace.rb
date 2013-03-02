module Termtter::Client
  # search replacement:
  # ADD: #[page] arg for list next pages
  register_command(
    :name => :search, :aliases => [:s],
    :exec_proc => lambda {|arg|
      search_option = config.search.option.empty? ? {} : config.search.option
      arg.slice!(/\s*#(\d+)$/)
      search_option[:page] = $1 if $1
      if arg.empty? && tags = public_storage[:hashtags]
        arg = tags.to_a.join(" ") 
      end
      statuses = Termtter::API.twitter.search(arg, search_option)
      public_storage[:search_keywords] << arg
      output(statuses, SearchEvent.new(arg))
    },
    :completion_proc => lambda {|cmd, arg|
      public_storage[:search_keywords].grep(/^#{Regexp.quote(arg)}/).map { |i| "#{cmd} #{i}" }
    },
    :help => ["search,s TEXT [#PAGE]", "Search for Twitter"]
  )

  # CHG: hit word highlight format
  register_hook(:highlight_for_search_query, :point => :pre_coloring) do |text, event|
    case event
    when SearchEvent
      query = event.query.split(/\s/).map {|q|Regexp.quote(q)}.join("|")
      text.gsub(/(#{query})/i, '<underline>\1</underline>')
    else
      text
    end
  end

  # list command replacement
  # ADD: #[page] arg for listing next pages
  register_command(
    :name => :list, :aliases => [:l],
    :exec_proc => lambda {|arg|
      options = {}
      arg.gsub!(/\s*([-#])(\d+)/) do
        case $1
        when '-' then options[:count] = $2
        when '#' then options[:page] = $2
        end
        ''
      end

      last_error = nil
      if arg.empty?
        event = :list_friends_timeline
        statuses = Termtter::API.twitter.home_timeline(options)
      else
        event = :list_user_timeline
        statuses = []
        Array(arg.split).each do |user|
          if user =~ /\/\w+/
            user_name, slug = *user.split('/')
            user_name = config.user_name if user_name.empty?
            user_name = normalize_as_user_name(user_name)
            options[:per_page] = options[:count]
            options.delete(:count)
            statuses += Termtter::API.twitter.list_statuses(user_name, slug, options)
          else
            begin
              if user =~ /^\d+$/
                profile = Termtter::API.twitter.user(nil, :screen_name => user) rescue nil
                unless profile
                  status  = Termtter::API.twitter.show(user) rescue nil
                  user    = status.user.screen_name if status
                end
              end
              user_name = normalize_as_user_name(user.sub(/\/$/, ''))
              statuses += Termtter::API.twitter.user_timeline(user_name, options)
            rescue Rubytter::APIError => e
              last_error = e
            end
          end
        end
      end
      output(statuses, event)
      raise last_error if last_error
    },
    :help => ["list,l [USERNAME]/[SLUG] [-COUNT] [#PAGE]", "List the posts"]
  )

  # uri-open replacement
  # ADD: some arg for open some uris in browser
  # CHG: accept ID without '$' at 'in [ID]' arg
  config.plugins.uri_open.set_default :some, 5
  register_command(
    :name => :'uri-open', :aliases => [:uo],
    :exec_proc => lambda {|arg|
      case arg.strip
      when ''
        open_uri public_storage[:uris].shift
      when /^all$/
        public_storage[:uris].
          each {|uri| open_uri(uri) }.
          clear
      when /^some\s*(\d*)$/
        some = $1.empty? ? config.plugins.uri_open.some : $1.to_i
        some.times do
          return unless uri = public_storage[:uris].shift
          open_uri(uri)
        end
      when /^list$/
        public_storage[:uris].
          enum_for(:each_with_index).
          to_a.
          reverse.
          each  do |uri, index|
            puts "#{index}: #{uri}"
          end
      when /^delete\s+(\d+)$/
        puts 'delete'
        public_storage[:uris].delete_at($1.to_i)
      when /^clear$/
        public_storage[:uris].clear
        puts "clear uris"
      when /^in\s+(.*)$/
        $1.split(/\s+/).each do |id|
          id = Termtter::Client.typable_id_to_data(id) unless id =~ /\d+/
          if s = Termtter::API.twitter.show(id) rescue nil
            URI.extract(s.text, PROTOCOLS).each do |uri|
              open_uri(uri)
              public_storage[:uris].delete(uri)
            end
          end
        end
      when /^(\d+)$/
        open_uri(public_storage[:uris].delete_at($1.to_i))
      else
        puts "**parse error in uri-open**"
      end
    },
    :completion_proc => lambda {|cmd, arg|
      %w(all list delete clear in some).grep(/^#{Regexp.quote arg}/).map {|a| "#{cmd} #{a}" }
    }
  )

  register_command(
    :name => :more,
    :exec_proc => lambda {|arg|
      break if Readline::HISTORY.length < 2
      i = Readline::HISTORY.length - 2
      input = ""
      cnt = 0
      begin
        input = Readline::HISTORY[i]
        i -= 1
        cnt += 1
        return if i <= 0
      end while input == "more" or input =~ /^(some|o|uri-open|uo|[0-7])/
      begin
        if input =~ /^(l|list|s|search|user search)(\s+|$)/
          input.slice!(/\s*#(\d+)/)
          cnt += $1.nil? ? 1 : $1.to_i
          Termtter::Client.execute(input + " ##{cnt}")
        end
        if input =~ /^(google_web|google|gs
                       |google_blog|gb
                       |google_book|gbk
                       |google_image|gi
                       |google_video|gv
                       |google_news|gn
                       |google_patent|gp
                       |google_next_page|gnext)(\s+|$)/x
          Termtter::Client.execute("google_next_page")
        end
      rescue CommandNotFound => e
        warn "Unknown command \"#{e}\""
        warn 'Enter "help" for instructions'
      rescue => e
        handle_error e
      end
    },
    :help => ["more", "List next results"]
  )

  # easy_post plugin replacement with confirm
  module Termtter::Client
    register_hook(:easy_post, :point => :command_not_found) do |text|
      if config.confirm && text.length > 15
        execute("update #{text}")
      else
        raise Termtter::CommandNotFound, text
      end
    end
  end

  # plugin plugin fix bug
  register_command(
    :name      => :plug,
    :alias     => :plugin,
    :exec_proc => lambda {|arg|
      if arg.empty?
        puts plugin_list.join(', ')
        return
      end
      begin
        result = plug arg
      rescue LoadError
      ensure
        puts "=> #{result.inspect}"
      end
    },
    :completion_proc => lambda {|cmd, args|
      plugin_list.grep(/#{Regexp.quote(args)}/).map {|i| "#{cmd} #{i}"}
    },
    :help => ['plug FILE', 'Load a plugin']
  )

end
