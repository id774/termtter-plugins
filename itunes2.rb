# -*- coding: utf-8 -*-
require 'appscript' or raise 'itunes plugin cannot run'

config.plugins.itunes.set_default(:prefix, 'Listening now:')
config.plugins.itunes.set_default(:suffix, '#iTunes #nowplaying')
config.plugins.itunes.set_default(
  :format,
  '<%=prefix%> <%=track_name%> (<%=time%>) <%=artist%> <%=album%> <%=uri%> <%=suffix%>')

module Termtter::Client
  register_command :name => :listening_now, :aliases => [:ln],
    :help => ['listening_now,ln', "Post the information of listening now"],
    :exec_proc => lambda {|args|
      begin
        prefix     = config.plugins.itunes.prefix
        track_name = Appscript.app('iTunes').current_track.name.get
        artist     = Appscript.app('iTunes').current_track.artist.get
        genre      = Appscript.app('iTunes').current_track.genre.get
        time       = Appscript.app('iTunes').current_track.time.get
        album      = Appscript.app('iTunes').current_track.album.get
        uri        = "http://www.last.fm/music/#{artist.split(' ').join('+')}/_/#{track_name.split(' ').join('+')}"
        suffix     = config.plugins.itunes.suffix
        erbed_text = ERB.new(config.plugins.itunes.format).result(binding)
        erbed_text.gsub!(/\s{2,}/, ' ')
        if args.length > 0
          erbed_text = args + ' ' + erbed_text
        end
        Termtter::API.twitter.update(erbed_text)
        puts "=> " << erbed_text
      rescue => e
        p e
      end
    }
end
