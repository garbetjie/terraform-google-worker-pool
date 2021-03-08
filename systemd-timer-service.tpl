[Unit]
Requires=docker.service ${cloudsql ? "cloudsql.service": ""}
After=docker.service ${cloudsql ? "cloudsql.service": ""}

[Service]
Type=oneshot
Environment=HOME=/home/chronos
ExecStartPre=/usr/bin/docker-credential-gcr configure-docker
ExecStart=/usr/bin/docker run \
  --rm \
  --name=${name} \
  --env-file /home/chronos/.env \
  ${cloudsql ? "-v cloudsql:${cloudsql_path}:ro" : ""} \
  ${image} \
  ${join(" ", args)}
ExecStop=/usr/bin/docker stop ${name}
