# -*- coding: utf-8 -*-

require File.expand_path(File.dirname(__FILE__)) + '/../spec_helper'

module Termtter
  describe Client, 'when the plugin is loaded' do
    it 'should add commands' do
      Termtter::Client.should_receive(:register_command).exactly(4)
      Termtter::Client.plug 'ar'
    end

    it 'self.insert should not return false' do
      Termtter::Client.plug 'ar'
      @status = Status.new
      @status.screen_name = 'hoge'
      @status.id_str = '55555'
      @status.text = 'ほげ'
      @status.protected = true
      @status.statuses_count = 500
      @status.friends_count = 1000
      @status.followers_count = 1500
      @status.source = 'Termtter tests'
      @status.save.should_not be_false
    end
  end
end
