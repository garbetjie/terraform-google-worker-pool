[Unit]
Requires=docker.service ${requires_cloudsql ? "cloudsql.service": ""}
After=docker.service ${requires_cloudsql ? "cloudsql.service": ""}

[Service]
Type=exec
Environment=HOME=/home/chronos
%{ for key, value in args }Environment=${key}=${value}
%{ endfor ~}
Restart=${restart}
RestartSec=${restart_sec}
%{ if requires_cloudsql }ExecStartPre=/bin/sh /tmp/scripts/wait-for-cloudsql.sh
%{ endif ~}
ExecStart=/usr/bin/docker run \
  --rm \
  --name=${systemd_name}-%i \
  --label part-of=worker \
  --env-file /home/chronos/.env \
  ${requires_cloudsql ? "-v cloudsql:${cloudsql_path}:ro" : ""} \
  ${image} ${join(" ", formatlist("$${%s}", keys(args)))}
ExecStop=-/usr/bin/docker stop ${systemd_name}-%i
