# encoding: UTF-8

module Myurls
  class App < Sinatra::Base

    register Sinatra::ActiveRecordExtension
    set :show_exceptions, :after_handler

    configure :production, :development do
      enable :logging
    end

    configure :production do
      set :database, {adapter: "sqlite3", database: "db/production.sqlite3"}
    end

    configure :development do
      register Sinatra::Reloader
      set :database, {adapter: "sqlite3", database: "db/development.sqlite3"}
    end

    configure :test do
      register Sinatra::Reloader
      set :database, {adapter: "sqlite3", database: "db/test.sqlite3"}
    end

    get '/' do
      @url = request.host
      unless request.port == 80 || request.port == 443
        @url += ":#{request.port}"
      end
      haml :url
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
      logger.info URI.parse(url).host
      logger.info request.host
      if URI.parse(url).host == request.host
        status 400
        body 'Invalid url'
        return
      end
      now = DateTime.now
      new_url = Urls.new
      new_url.url = url
      new_url.short = Myurls::Utils.shorten url, now.to_s
      new_url.created_at = now
      new_url.save!
      new_url.short
    end

    get '/signin' do
      haml :signin
    end

    get '/signup' do
      haml :signup
    end

    get '/:url' do
      logger.info "-----> #{params[:url]}"
      url = Urls.find_by_short(params[:url])
      if url.nil? or url.url.empty?
        halt 404
      else
        redirect url.url, 301
      end
    end
  end
end
