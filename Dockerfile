FROM ruby:3.2.2-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libsqlite3-dev \
    net-tools \
    tini \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

RUN mkdir -p /app/db

COPY Gemfile Gemfile.lock ./

RUN bundle install --jobs 4 --retry 3

COPY . .

ENV APP_ENV=production \
    RACK_ENV=production

EXPOSE 9292

# Add tini as entrypoint
ENTRYPOINT ["/usr/bin/tini", "--"]

# Default command
CMD ["bundle", "exec", "rackup", "-o", "0.0.0.0"]
