FROM ruby:2.5.3
MAINTAINER Jiang Yucheng <fatjyc@gmail.com>

RUN apt-get update && \
    apt-get install -y net-tools

RUN mkdir /app

WORKDIR /app
COPY . /app
RUN bundle install --system

ARG domain
ENV domain ${domain:-127.0.0.1:9292}
ARG url_file_path
ENV url_file_path ${url_file_path:-domain.json}
EXPOSE 9292
ENTRYPOINT bundle exec unicorn -c config/unicorn.rb
