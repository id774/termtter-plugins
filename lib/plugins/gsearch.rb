# -*- encoding: utf-8 -*-
require "google-search"

module Google
  class Search
    def self.url_encode string
      string.to_s.gsub(/([^ a-zA-Z0-9_.-]+)/) {
        '%' + $1.unpack('H*')[0].scan(/../).join('%').upcase
      }.tr(' ', '+')
    end
  end
end

module Termtter::Client
  # for All Searches
  # :verbose = :true, :false
  # :colors = ex. ['green', 'on_yellow', 'underline']
  # :lang = ex. :ja, :en, :cn, :fr..
  # :page_size = :small, :large (4 : 8)
  # :site = ex. 'ja.wikipedia.org'
  config.plugins.google.set_default :verbose, false
  config.plugins.google.set_default :colors, ['green']
  config.plugins.google.set_default :lang, :ja
  config.plugins.google.set_default :page_size, :large
  config.plugins.google.set_default :site, nil
  # for Google News
  # :news_edition = ex. :jp, :us, :uk, :fr_ca..
  # :news_topic = :headlines, :world, :business, :nation, :science,
  #               :elections, :politics, :entertainment, :sports, :health
  # :news_relative_to = ex. city, state, province, zipcode..
  config.plugins.google.set_default :news_edition, :jp
  config.plugins.google.set_default :news_topic, :headlines
  config.plugins.google.set_default :news_relative_to, nil
  # for Google Image
  # :image_size = :icon, :small, :medium, :large, :xlarge, :xxlarge, :huge
  # :image_type = :face, :photo, :clipart, :lineart
  # :file_type = :jpg, :png, :gif, :bmp
  config.plugins.google.set_default :image_color, nil
  config.plugins.google.set_default :image_size, nil
  config.plugins.google.set_default :image_type, nil
  config.plugins.google.set_default :file_type, nil
  # for Google Patent
  config.plugins.google.set_default :patent_issued_only, false

  public_storage[:google] = nil
  public_storage[:google_verbose] = nil

  class << self
    def print_search_result(search, verbose)
      search.response.reverse_each.with_index do |res, i|
        public_storage[:uris].unshift res.uri
        puts colorize("#{search.response.items.length-1-i}: #{res.title}") +
             " <underline>#{res.uri}</underline>".termcolor
        puts "\t#{res.content}".gsub(/\<b\>\w+\<\/b\>/, '<red>\0</red>').termcolor if verbose
      end
      public_storage[:google] = search
      public_storage[:google_verbose] = verbose
    end

    def colorize(str)
      config.plugins.google.colors.each { |c| str = TermColor.colorize(str, c) }
      str
    end
  end

  GOOGLE_SEARCHES = {
    :google_web    => [ [:google, :gs], ['google_web,google,gs [-lvp VALUE] [--site] QUERY', 'Google Web Search']],
    :google_blog   => [ [:gb], ['google_blog,gb [-lvp VALUE] [--site] QUERY', 'Google Blog Search']],
    :google_book   => [ [:gbk],['google_book,gbk [-lp VALUE] QUERY', 'Google Book Search']],
    :google_image  => [ [:gi], ['google_image,gi [-ctfslvp VALUE] [--site] QUERY', 'Google Image Search']],
    :google_video  => [ [:gv], ['google_video,gv [-lvp VALUE] [--site] QUERY', 'Google Video Search']],
    :google_news   => [ [:gn], ['google_news,gn [-etrvp VALUE] QUERY', 'Google News Search']],
    :google_patent => [ [:gp], ['google_patent,gp [-ivp VALUE] QUERY', 'Google Patent Search']]
  }

  GOOGLE_SEARCHES.each do |name, attrs|
    register_command(
      :name => name, :aliases => attrs[0], :help => attrs[1],
      :exec => lambda do |query|
        opts = {}
        target = name.to_s.sub(/^\w+_/,'').capitalize
        search = instance_eval("Google::Search::#{target}").new do |s|
          if config.plugins.google.site && query.sub!(/--site/, '')
            query += " site:#{URI.escape(config.plugins.google.site)}"
          end
          query.gsub!(/-(l|p|v)\s+:*(\w+)\s*/) { opts[$1.to_sym] = $2.to_sym ; nil }
          s.query    = query
          s.language = opts[:l] || config.plugins.google.lang
          s.size     = opts[:p] || config.plugins.google.page_size
          case target
          when 'News'
            query.gsub!(/-(e|t|r)\s+:*(\w+)\s*/) { opts[$1.to_sym] = $2.to_sym ; nil }
            s.edition     = opts[:e] || config.plugins.google.news_edition
            s.topic       = opts[:t] || config.plugins.google.news_topic
            s.relative_to = opts[:r] || config.plugins.google.news_relative_to
          when 'Image'
            query.gsub!(/-(c|s|t|f)\s+:*(\w+)\s*/) { opts[$1.to_sym] = $2.to_sym ; nil }
            s.color       = opts[:c] || config.plugins.google.image_color
            s.image_size  = opts[:s] || config.plugins.google.image_size
            s.image_type  = opts[:t] || config.plugins.google.image_type
            s.file_type   = opts[:f] || config.plugins.google.file_type
          when 'Patent'
            query.gsub!(/-(i)\s+:*(\w+)\s*/) { opts[$1.to_sym] = $2.to_sym ; nil }
            s.issued_only = opts[:i] || config.plugins.google.patent_issued_only
          end
        end
        mode = opts[:v] || config.plugins.google.verbose
        print_search_result(search, mode)
      end
    )
  end

  register_command(
    :name => :google_next_page, :alias => :gnext,
    :help => ['google_next_page,gnext', 'List Next Google Search Results'],
    :exec_proc => lambda { |arg|
      begin
        search = public_storage[:google].next
        verbose = public_storage[:google_verbose] || false
        print_search_result(search, verbose)
      rescue
      end
    }
  )

  nums = config.plugins.google.page_size == :small ? 4 : 8
  nums.times { |n| register_alias("#{n}", "uo #{n}") }
end
