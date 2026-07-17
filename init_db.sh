#!/usr/bin/env bash

set -euo pipefail

cur_dir=$(cd "$(dirname "$0")"; pwd)
cd "$cur_dir"

mkdir -p db
docker compose build myurls
docker compose run --rm myurls bundle exec rake db:migrate
