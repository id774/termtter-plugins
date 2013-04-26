# -*- coding: utf-8 -*-

APP_ROOT = File.expand_path(File.join(File.dirname(__FILE__), ".."))
$LOAD_PATH.unshift APP_ROOT
$LOAD_PATH.unshift File.join(APP_ROOT)
$LOAD_PATH.unshift File.join(APP_ROOT, 'lib')
ARGV.delete '-c'
require 'termtter'

if ENV['COVERAGE'] == 'on'
  require 'simplecov'
  require 'simplecov-rcov'
  SimpleCov.formatter = SimpleCov::Formatter::RcovFormatter

  SimpleCov.start do
    add_filter "spec"
    add_filter "vendor"
  end
end

if RUBY_VERSION < '1.9.0'
  require 'rspec'
end

RSpec.configure do |config|
end
