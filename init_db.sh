#!/usr/bin/env bash

cur_dir=$(cd $(dirname $0); pwd)

rm -fr ${cur_dir}/db/production.sqlite3

docker run --rm -v ${cur_dir}/db:/app/db -e APP_ENV=production -w /app jiong/myurls bash -cx "bundle exec rake db:migrate"