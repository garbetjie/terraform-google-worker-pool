#!/usr/bin/env sh

started="$(date +%s)"

while true; do
  now="$(date +%s)"

  # Don't wait longer than 30 seconds for CloudSQL to start.
  if [ $((now - started)) -gt 30 ]; then
    echo "CloudSQL taking longer than 30 seconds to start up."
    exit 1
  fi

  if [ "$(find /var/lib/docker/volumes/cloudsql/_data -maxdepth 1 -mindepth 1 | wc -l)" = 1 ]; then
    break
  else
    echo "Waiting for CloudSQL sockets to be available."
    sleep 0.2
  fi
done