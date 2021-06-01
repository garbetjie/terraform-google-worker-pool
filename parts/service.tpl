[Unit]
Requires=docker.service ${cloudsql_required ? "cloudsql.service": ""}
After=docker.service ${cloudsql_required ? "cloudsql.service": ""}

[Service]
Type=${type}
Environment=HOME=/etc/runtime
EnvironmentFile=/etc/runtime/args/${arg_file}
%{ if cloudsql_wait }ExecStartPre=/bin/sh /etc/runtime/scripts/wait-for-cloudsql.sh
%{ endif ~}
%{ if length(pre_start) > 0 }ExecStartPre=${join("\nExecStartPre=", pre_start)}
%{ endif ~}
ExecStart=${start}
ExecStop=${stop}
