[Unit]
Requires=docker.service ${requires_cloudsql ? "cloudsql.service": ""}
After=docker.service ${requires_cloudsql ? "cloudsql.service": ""}

[Service]
Type=oneshot
Environment=HOME=/home/chronos
%{ for key, value in timer.command }Environment=${format("ARG%d", key)}=${value}
%{ endfor ~}
%{ if requires_cloudsql }ExecStartPre=/bin/sh /tmp/scripts/wait-for-cloudsql.sh
%{ endif ~}
ExecStart=/usr/bin/docker run \
  --rm \
  --name=${timer.name} \
  --label part-of=timer \
  --env-file /home/chronos/.env \
  ${cloudsql ? "-v cloudsql:${cloudsql_path}:ro" : ""} \
  ${image} ${join(" ", formatlist("$${ARG%d}", keys(timer.command)))}
ExecStop=/usr/bin/docker stop ${name}
