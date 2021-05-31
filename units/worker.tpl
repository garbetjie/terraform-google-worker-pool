[Unit]
Requires=docker.service ${requires_cloudsql ? "cloudsql.service": ""}
After=docker.service ${requires_cloudsql ? "cloudsql.service": ""}

[Service]
Type=exec
Environment=HOME=/etc/runtime
EnvironmentFile=/etc/runtime/args/worker
Restart=${restart}
RestartSec=${restart_sec}
%{ if wait_for_cloudsql }ExecStartPre=/bin/sh /tmp/scripts/wait-for-cloudsql.sh
%{ endif ~}
ExecStart=/usr/bin/docker run \
  --rm \
  --name=${systemd_name}-%i \
  --label part-of=worker \
  --env-file /etc/runtime/env \
%{ if user != null } -u ${user} \
%{ endif ~}
%{ if length(mounts) > 0 }  --mount ${join(" --mount ", [for m in mounts: "type=${m.type},src=${m.src},dst=${m.target}${m.readonly ? ",readonly" : ""}"])} \
%{ endif ~}
%{ if length(expose_ports) > 0 }  -p ${join(" -p ", formatlist("%s:%d:%d/%s", expose_ports.*.host, expose_ports.*.port, expose_ports.*.container_port, expose_ports.*.protocol))} \
%{ endif ~}
%{ if requires_cloudsql }  -v cloudsql:${cloudsql_path}:ro \
%{ endif ~}
  ${image} ${join(" ", formatlist("$${ARG%d}", range(length(command))))}
ExecStop=-/usr/bin/docker stop ${systemd_name}-%i
