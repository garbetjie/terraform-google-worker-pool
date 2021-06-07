[Unit]
Requires=${join(" ", concat(["docker.service"], lookup(Unit, "Requires", [])))}
After=${join(" ", concat(["docker.service"], lookup(Unit, "After", [])))}

[Service]
Type=${lookup(Service, "Type", "exec")}
Environment=HOME=/etc/runtime
%{ if lookup(Service, "EnvironmentFile", null) != null }EnvironmentFile=${Service.EnvironmentFile}
%{ endif ~}
%{ if lookup(Service, "Restart", null) != null }Restart=${Service.Restart}
%{ endif ~}
%{ if lookup(Service, "RestartSec", null) != null }RestartSec=${Service.RestartSec}
%{ endif ~}
%{ if length(lookup(Service, "ExecStartPre", [])) > 0 }ExecStartPre=${join("\nExecStartPre=", [for esp in Service.ExecStartPre: trimspace(esp)])}
%{ endif ~}
%{ if lookup(Service, "ExecStart", null) != null }ExecStart=${trimspace(Service.ExecStart)}
%{ endif ~}
%{ if lookup(Service, "ExecStop", null) != null }ExecStop=${trimspace(Service.ExecStop)}
%{ endif ~}
