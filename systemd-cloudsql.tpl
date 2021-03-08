[Unit]
Requires=docker.service
After=docker.service

[Service]
Type=simple
Environment=HOME=/home/chronos
Restart=on-failure
RestartSec=1
ExecStart=/usr/bin/docker run \
  --rm \
  --name cloudsql \
  -v cloudsql:/cloudsql \
  -u root \
  gcr.io/cloudsql-docker/gce-proxy:1.19.1-alpine \
    ./cloud_sql_proxy \
    -dir /cloudsql \
    -instances ${join(",", connections)}
ExecStop=/usr/bin/docker stop cloudsql
