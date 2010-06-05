# -*- encoding:utf-8 -*-
require "net/imap"
require "kconv"
require "termcolor"

class Gmail
  def initialize(username, password)
    begin
      @imap = Net::IMAP.new('imap.gmail.com', 993, true, nil, false)
      @imap.login(username, password)
    rescue Exception => e
      puts e
      exit
    end
  end

  def fetch(select="INBOX", ids="UNSEEN")
    begin
      puts "fetching gmail messages..."
      @imap.examine(select)
      ids = @imap.search(ids)
      puts "you have <red>#{ids.length}</red> unread messages.".termcolor
      return if ids.length < 1
      @imap.fetch(ids, "ENVELOPE").each_with_index do |mail, i|
        sender = mail.attr["ENVELOPE"].sender[0]
        name = sender.name || sender.mailbox || sender.host
        subject = mail.attr["ENVELOPE"].subject || "(no subject)"
        puts "<90>#{i+1}:</90><green>#{name.toutf8} : </green>".termcolor +
             TermColor.colorize("#{subject.toutf8}", 'yellow')
      end
    rescue Exception => e
      puts e
    ensure
      @imap.disconnect
    end
  end
end

