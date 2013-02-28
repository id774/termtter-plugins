# -*- coding: utf-8 -*-

require File.expand_path(File.dirname(__FILE__)) + '/../spec_helper'

module Termtter
  describe Client, 'when the plugin is loaded' do
    it 'should add commands' do
      Termtter::Client.should_receive(:register_command).exactly(4)
      Termtter::Client.plug 'ar'
    end

    it 'should set public_storage[:ar]' do
      Termtter::Client.plug 'filter'
      Client::public_storage.keys.should be_include(:filters)
    end
  end
end
