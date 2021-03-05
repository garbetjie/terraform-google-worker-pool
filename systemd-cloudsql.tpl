[Service]
Type=simple
Environment=HOME=/home/chronos
Restart=on-failure
RestartSec=1
ExecStartPre=/usr/bin/docker pull gcr.io/cloudsql-docker/gce-proxy:latest
ExecStart=/usr/bin/docker run \
  --name cloudsql \
  -v cloudsql:/cloudsql \
  gcr.io/cloudsql-docker/gce-proxy:latest \
    ./cloud_sql_proxy \
    -dir /cloudsql \
    -instances ${join(",", connections)}
ExecStop=/usr/bin/docker stop cloudsql
