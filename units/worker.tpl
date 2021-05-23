[Unit]
Requires=docker.service ${requires_cloudsql ? "cloudsql.service": ""}
After=docker.service ${requires_cloudsql ? "cloudsql.service": ""}

[Service]
Type=exec
Environment=HOME=/home/chronos
EnvironmentFile=/etc/runtime/args/worker
Restart=${restart}
RestartSec=${restart_sec}
%{ if wait_for_cloudsql }ExecStartPre=/bin/sh /tmp/scripts/wait-for-cloudsql.sh
%{ endif ~}
ExecStart=/usr/bin/docker run \
  --rm \
  --name=${systemd_name}-%i \
  --label part-of=worker \
  --env-file /home/chronos/.env \
%{ if requires_cloudsql }  -v cloudsql:${cloudsql_path}:ro \
%{ endif ~}
  ${image} ${join(" ", formatlist("$${ARG%d}", range(length(command))))}
ExecStop=-/usr/bin/docker stop ${systemd_name}-%i
