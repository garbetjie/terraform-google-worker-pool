[Unit]
Requires=docker.service ${requires_cloudsql ? "cloudsql.service": ""}
After=docker.service ${requires_cloudsql ? "cloudsql.service": ""}

[Service]
Type=oneshot
Environment=HOME=/etc/runtime
EnvironmentFile=/etc/runtime/args/timer-${name}
%{ if wait_for_cloudsql }ExecStartPre=/bin/sh /tmp/scripts/wait-for-cloudsql.sh
%{ endif ~}
ExecStart=/usr/bin/docker run \
  --rm \
  --name=${name} \
  --label part-of=timer \
  --env-file /etc/runtime/env \
%{ if user != null }  -u ${user} \
%{ endif ~}
%{ if length(mounts) > 0 }  --mount ${join(" --mount ", [for m in mounts: available_mounts[m]])} \
%{ endif ~}
%{ if requires_cloudsql }  -v cloudsql:${cloudsql_path}:ro \
%{ endif ~}
  ${image} ${join(" ", formatlist("$${ARG%d}", range(length(command))))}
ExecStop=-/usr/bin/docker stop ${name}
