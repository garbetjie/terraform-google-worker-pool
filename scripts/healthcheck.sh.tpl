#!/usr/bin/env sh

container_name="health-check-$(hostname | hexdump -n 4 -e '1/4 "%08x"')"

while true; do
  running_workers_count="$(docker ps -f status=running -f label=part-of=worker --format '{{ .Names }}' | wc -l)"
  running_cloudsql_count="$(docker ps -f status=running -f name=cloudsql --format '{{ .Names }}' | wc -l)"
  running_total_count="$((running_workers_count + running_cloudsql_count))"

  # Check whether the health check is currently running.
  is_health_check_running=false
  if [ "$(docker ps -q -f "name=$${container_name}")" != "" ]; then is_health_check_running=true; fi

  # The expected number of containers is running. Start up the health check container if it's not already running.
  if [ "$running_total_count" = "${expected_count}" ]; then
    if [ "$is_health_check_running" = false ]; then
      echo "open port"
      docker run --name "$container_name" -d --rm -p "${health_check_port}:1025" alpine nc -d -k -l 1025
    fi
  # Otherwise, the expected number of containers aren't running. Stop the health check container if it's still running.
  else
    if [ "$is_health_check_running" = true ]; then
      echo "close port"
      docker rm -f "$container_name"
    fi
  fi

  sleep 1
done