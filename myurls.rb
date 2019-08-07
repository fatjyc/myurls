# encoding: UTF-8

module Myurls
  class App < Sinatra::Base

    begin
      @@url_map = Hash[]

      cnf = YAML::load_file(File.join(__dir__, 'config.yml'))
      @@domain = cnf['domain']
    rescue
      @@domain = ENV['domain'] || '127.0.0.1'
    end

    configure :development do
      register Sinatra::Reloader
    end

    get '/' do
      # erb :index
      @domain = @@domain
      erb :url
    end

    get '/url' do
      @domain = @@domain
      erb :url
    end

    post '/url' do
      url = @params[:url]
      short_url = Myurls::Url.shorten url
      @@url_map[short_url] = url
      short_url
    end

    get '/signin' do
      erb :signin
    end

    get '/signup' do
      erb :signup
    end

    get '/:url' do
      if @@url_map[params[:url]]
        redirect @@url_map[params[:url]], 301
      else
        halt 404
      end
    end
  end
end
