%{if cloudsql}
[Unit]
Requires=cloudsql.service
%{endif}

[Service]
Type=simple
Environment=HOME=/home/chronos
Restart=on-failure
RestartSec=3
ExecStartPre=/usr/bin/docker-credential-gcr configure-docker
ExecStart=/usr/bin/docker run \
  --rm \
  --name=worker-%i \
  --env-file /home/chronos/.env \
  ${cloudsql ? "-v cloudsql:${cloudsql_path}:ro" : ""} \
  ${image} \
  ${join(" ", args)}
ExecStop=/usr/bin/docker stop worker-%i
