#!/usr/bin/env sh

while true; do
  running_workers_count="$(docker ps -f status=running -f label=part-of=worker --format '{{ .Names }}' | wc -l)"
  running_cloudsql_count="$(docker ps -f status=running -f name=cloudsql --format '{{ .Names }}' | wc -l)"
  running_total_count="$((running_workers_count + running_cloudsql_count))"

  if [ "$running_total_count" = "${expected_count}" ]; then
    echo "open port"
    docker start "$container_name"
  else
    echo "close port"
    docker stop "$container_name"
  fi

  sleep 1
done