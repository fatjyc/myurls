#!/usr/bin/env bash

docker run --rm -v `pwd`/db:/app/db -e APP_ENV=production -w /app jiong/myurls bash -cx "bundle exec rake db:migrate"