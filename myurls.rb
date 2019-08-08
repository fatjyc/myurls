# encoding: UTF-8

module Myurls
  class App < Sinatra::Base

    set :show_exceptions, :after_handler

    configure :production, :development do
      enable :logging
    end

    begin
      cnf = YAML::load_file(File.join(__dir__, 'config.yml'))
      @@url_file_path = cnf['url_file_path']
    rescue
      @@url_file_path = ENV['url_file_path'] || 'domain.json'
    end

    configure :development do
      register Sinatra::Reloader
    end

    get '/' do
      # erb :index
      @url = request.host
      unless request.port == 80 || request.port == 443
        @url += ":#{request.port}"
      end
      erb :url
    end

    get '/url' do
      erb :url
    end

    post '/url' do
      url = @params[:url]
      logger.info url
      if url.nil? || url.empty?
        status 400
        body 'Invalid url'
        return
      end
      unless url =~ URI::regexp
        status 400
        body 'Invalid url'
        return
      end
      short_url = Myurls::Url.shorten url
      begin
        url_file = File.read(@@url_file_path)
        @@url_map = JSON.parse(url_file)
      rescue
        @@url_map = Hash[]
      end
      @@url_map[short_url] = url
      File.open(@@url_file_path,"w") do |f|
        f.write(@@url_map.to_json)
      end
      short_url
    end

    get '/signin' do
      erb :signin
    end

    get '/signup' do
      erb :signup
    end

    get '/:url' do
      begin
        url_file = File.read(@@url_file_path)
        @@url_map = JSON.parse(url_file)
      rescue
        @@url_map = Hash[]
      end
      if @@url_map[params[:url]]
        redirect @@url_map[params[:url]], 301
      else
        halt 404
      end
    end
  end
end
