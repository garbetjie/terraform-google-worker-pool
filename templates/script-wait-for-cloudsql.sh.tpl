#!/usr/bin/env sh

started="$(date +%s)"
wait_duration="${wait_duration}"

while true; do
  now="$(date +%s)"

  # Don't wait longer than ${wait_duration} seconds for CloudSQL to start.
  if [ "$wait_duration" -gt 0 ] && [ $((now - started)) -gt "$wait_duration" ]; then
    echo "CloudSQL taking longer than $${wait_duration} seconds to start up."
    exit 1
  fi

  if [ "$(find /var/lib/docker/volumes/cloudsql/_data -maxdepth 1 -mindepth 1 | wc -l)" = 1 ]; then
    break
  else
    echo "Waiting for CloudSQL sockets to be available."
    sleep 0.2
  fi
done