require 'rubygems'

require 'sinatra/base'
require 'sinatra/json'
require 'sinatra/reloader'

require 'yaml'
require 'erb'
require 'net/https'
require 'uri'

require 'json'

require File.join(File.dirname(__FILE__), '..', 'myurls')
%w[url].each do |lib|
  require File.join(File.dirname(__FILE__), '..', 'lib', lib)
end
