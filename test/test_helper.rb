ENV['APP_ENV'] = 'test'

require File.join(File.dirname(__FILE__), '..', 'config', 'environment')
require 'minitest/autorun'
require 'rack/test'
require "minitest/reporters"
Minitest::Reporters.use!
