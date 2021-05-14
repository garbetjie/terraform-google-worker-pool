[Unit]
Requires=docker.service ${requires_cloudsql ? "cloudsql.service": ""}
After=docker.service ${requires_cloudsql ? "cloudsql.service": ""}

[Service]
Type=oneshot
Environment=HOME=/home/chronos
%{ for index in range(length(timer.command)) }Environment=${format("ARG%d", index)}=${timer.command[index]}
%{ endfor ~}
%{ if wait_for_cloudsql }ExecStartPre=/bin/sh /tmp/scripts/wait-for-cloudsql.sh
%{ endif ~}
ExecStart=/usr/bin/docker run \
  --rm \
  --name=${timer.name} \
  --label part-of=timer \
  --env-file /home/chronos/.env \
  ${requires_cloudsql ? "-v cloudsql:${cloudsql_path}:ro" : ""} \
  ${image} ${join(" ", formatlist("$${ARG%d}", range(length(timer.command))))}
ExecStop=-/usr/bin/docker stop ${timer.name}
