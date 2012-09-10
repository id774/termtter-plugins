require 'set'

module Termtter::Client
  help = ['favorites,favlist,f USERNAME', 'show user favorites']
  Termtter::Client.register_command(:favorites, :alias => :f, :help => help) do |arg|
    output(Termtter::API.twitter.favorites(arg), Termtter::Event.new(:user_timeline, :type => :favorite))
  end
end
