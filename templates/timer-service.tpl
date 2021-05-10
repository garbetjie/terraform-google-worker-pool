[Unit]
Requires=docker.service ${requires_cloudsql ? "cloudsql.service": ""}
After=docker.service ${requires_cloudsql ? "cloudsql.service": ""}

[Service]
Type=oneshot
Environment=HOME=/home/chronos
%{ for key, value in timer.args }Environment=${key}=${value}
%{ endfor ~}
ExecStartPre=/usr/bin/docker-credential-gcr configure-docker
ExecStart=/usr/bin/docker run \
  --rm \
  --name=${timer.name} \
  --env-file /home/chronos/.env \
  ${cloudsql ? "-v cloudsql:${cloudsql_path}:ro" : ""} \
  ${image} \
  ${join(" ", formatlist("$${%s}", keys(timer.args)))}
ExecStop=/usr/bin/docker stop ${name}
