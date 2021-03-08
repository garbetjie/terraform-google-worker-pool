[Unit]
Requires=docker.service ${cloudsql ? "cloudsql.service": ""}
After=docker.service ${cloudsql ? "cloudsql.service": ""}

[Service]
Type=simple
Environment=HOME=/home/chronos
Restart=on-failure
RestartSec=3
ExecStartPre=/usr/bin/docker-credential-gcr configure-docker
ExecStart=/usr/bin/docker run \
  --rm \
  --name=${prefix}-%i \
  --env-file /home/chronos/.env \
  ${cloudsql ? "-v cloudsql:${cloudsql_path}:ro" : ""} \
  ${image} \
  ${join(" ", args)}
ExecStop=/usr/bin/docker stop ${prefix}-%i
