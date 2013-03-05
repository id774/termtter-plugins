# -*- coding: utf-8 -*-

require File.expand_path(File.dirname(__FILE__)) + '/../spec_helper'

describe Termtter do
  it 'plugin mashimaro' do
    Termtter::Client.should_receive(:register_command).at_least(1).times
    Termtter::Client.plug 'mashimaro'
  end
end
