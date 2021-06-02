/usr/bin/docker run --rm --name ${name} --env-file /etc/runtime/envs/${env_file}
%{~ if user != null } -u ${user}
%{~ endif ~}
%{~ if length(labels) > 0 } --label ${join(" --label ", [for k, v in labels: format("\"%s=%s\"", k, v)])}
%{~ endif ~}
%{~ if length(mounts) > 0 } --mount ${join(" --mount ", [for m in mounts: format("type=%s,src=%s,dst=%s%s", m.type, m.src, m.target, m.readonly ? ",readonly" : "")])}
%{~ endif ~}
%{~ if length(expose) > 0 } -p ${join(" -p ", [for e in expose: format("%s:%s:%s/%s", e.host, e.port, e.container_port, e.protocol)])}
%{~ endif ~}
 ${image} ${join(" ", formatlist("$${ARG%d}", range(length(command))))}
