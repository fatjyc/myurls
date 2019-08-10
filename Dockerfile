FROM ruby:2.6.3
MAINTAINER Jiang Yucheng <fatjyc@gmail.com>

RUN apt-get update && \
    apt-get install -y net-tools

RUN mkdir /app

WORKDIR /app
COPY . /app
RUN bundle install --system

ENV APP_ENV production
EXPOSE 9292
# ENTRYPOINT APP_ENV=production bundle exec unicorn -c config/unicorn.rb
