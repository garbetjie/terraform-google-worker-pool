[Unit]
Requires=docker.service ${join(" ", requires)}
After=docker.service ${join(" ", requires)}

[Service]
Type=${type}
Environment=HOME=/etc/runtime
EnvironmentFile=/etc/runtime/args/${arg_file}
%{ if length(exec_start_pre) > 0 }ExecStartPre=${join("\nExecStartPre=", [for p in exec_start_pre: trimspace(p)])}%{~ endif }
ExecStart=${trimspace(exec_start)}
ExecStop=${trimspace(exec_stop)}