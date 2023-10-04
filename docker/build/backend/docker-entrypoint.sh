#!/bin/bash

while ! pg_isready -q -h $DB_HOST -p 5432 -U $DB_USER; do
  echo "$(date) - waiting for database to start..."
  sleep 1
done

if [ -z "$1" ]; then set -- /app/bin/server "$@"; fi

exec "$@"
