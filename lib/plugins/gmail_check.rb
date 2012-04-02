require_relative "gmail"

module Termtter::Client
  register_command(
    :name => :gmail, :alias => :gm,
    :help => ["gmail,gm", "Just check unread gmail messages"],
    :exec_proc => lambda { |arg|
      username = config.plugins.gmail.username
      password = config.plugins.gmail.password
      if username.empty?
        username = create_highline.ask('Username: ')
      end
      if password.empty?
        password = create_highline.ask('Password: ') { |q| q.echo = false }
      end
      Gmail.new(username, password).fetch
    }
  )
  
  register_command(
    :name => :gmail_open, :alias => :gmo,
    :help => ["gmail_open,gmo", "Open gmail with your browser"],
    :exec_proc => lambda { |arg| open_uri "https://mail.google.com"}
  )
end

