[Unit]
Requires=docker.service
After=docker.service

[Service]
Type=exec
Environment=HOME=/home/chronos
Restart=${restart}
RestartSec=${restart_sec}
ExecStartPre=/usr/bin/docker run --rm -u root -v cloudsql:/cloudsql gcr.io/cloudsql-docker/gce-proxy:1.19.1-alpine /bin/sh -c 'chown nonroot:nonroot /cloudsql'
ExecStart=/usr/bin/docker run \
  --rm \
  --name cloudsql \
  --label part-of=cloudsql \
  -v cloudsql:/cloudsql \
  gcr.io/cloudsql-docker/gce-proxy:1.19.1-alpine ./cloud_sql_proxy -dir /cloudsql -instances ${join(",", connections)}
ExecStop=-/usr/bin/docker stop cloudsql
