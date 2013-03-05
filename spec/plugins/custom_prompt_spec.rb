# -*- coding: utf-8 -*-

require File.expand_path(File.dirname(__FILE__)) + '/../spec_helper'

describe Termtter do
  it 'plugin custom_prompt' do
    Termtter::Client.should_receive(:register_command).exactly(0).times
    Termtter::Client.plug 'custom_prompt'
  end
end
