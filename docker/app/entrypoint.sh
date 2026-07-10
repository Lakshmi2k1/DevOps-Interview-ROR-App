#!/bin/sh
set -e

echo "bundle installation"
bundle check || bundle install

echo "database migration (safe for production)"
# db:prepare is idempotent and production-safe:
# - creates DB if needed
# - runs pending migrations
# - avoids destructive schema:load in production
bundle exec rails db:prepare

if [ -f tmp/pids/server.pid ]; then
  rm tmp/pids/server.pid
fi

exec "$@"