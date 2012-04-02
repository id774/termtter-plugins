# -*- coding:utf-8 -*-

if RUBY_VERSION < '1.9.0'
  $KCODE = 'u'
  require "jcode"
end

class String
  def mirror(opt)
    reversed = RUBY_VERSION < '1.9.0' ? self.split(//).reverse.join : self.reverse 
    opt.empty? ? self.replace(reversed) : self.replace(self.chop + reversed)
  end
  def rot13(opt=nil)
    from = 'A-Ma-mN-Zn-zあ-なア-ナに-んニ-ン'
    to   = 'N-Zn-zA-Ma-mに-んニ-ンあ-なア-ナ'
    if RUBY_VERSION >= '1.9.0'
      from += '一-盒盓-龥'
      to += '盓-龥一-盒'
    end
    self.tr(from, to)
  end
  def scooch(opt)
    opt = opt.to_i.zero? ? 1 : opt.to_i
    self.split(//).map { |c| opt.times { c = c.next }; c }.join
  end
end

module Termtter::Client
  uglies = {
    :update_mirror => [[:um], :mirror, 'Mirror message'],
    :update_rot13  => [[:u13], :rot13, 'Rot13 message'],
    :update_scooch => [[:us], :scooch, 'Scooch message'],
    :update_crypt  => [[:uc], :crypt, 'Crypt message']
  }

  uglies.each do |name, (aliases, meth, help)|
    register_command(
      :name => name, :aliases => aliases,
      :exec_proc => lambda {|arg|
        opt = ''
        arg.sub!(/^-\s*([\d\w]+)\s+/) { opt = $1; '' }
        text = "#{arg.send(meth, opt)} ##{meth.to_s}message"
        text = text + "#{opt}" if [:update_crypt, :update_scooch].include? name
        Termtter::API::twitter.update(text)
        puts "=> #{text}"
      },
      :help => ["#{name},#{aliases.join(',')} [-VALUE] TEXT", help]
    )
  end
end
