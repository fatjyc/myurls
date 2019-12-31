require 'rubygems'

require 'sinatra/base'
require 'sinatra/json'
require 'sinatra/reloader'
require "sinatra/activerecord"

require 'yaml'
require 'erb'
require 'net/https'
require 'uri'
require 'haml'

require 'json'

require File.join(File.dirname(__FILE__), '..', 'myurls')
%w[utils urls].each do |lib|
  require File.join(File.dirname(__FILE__), '..', 'lib', lib)
end
