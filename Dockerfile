FROM ruby:2.6.3

RUN apt-get update && apt-get install -y --no-install-recommends net-tools

RUN mkdir /app

WORKDIR /app
COPY . /app
RUN bundle install --system

ENV APP_ENV production
EXPOSE 9292
# ENTRYPOINT APP_ENV=production bundle exec unicorn -c config/unicorn.rb
