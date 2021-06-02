/usr/bin/docker run --rm --name ${name} --env-file /etc/runtime/envs/${env_file}
%{~ if user != null } -u ${user}
%{~ endif ~}
%{~ if length(labels) > 0 } --label ${join(" --label ", [for k, v in labels: format("\"%s=%s\"", k, v)])}
%{~ endif ~}
%{~ if length(mounts) > 0 } --mount ${join(" --mount ", mounts)}
%{~ endif ~}
%{~ if length(expose) > 0 } -p ${join(" -p ", expose)}
%{~ endif ~}
 ${image} ${join(" ", formatlist("$${ARG%d}", range(length(command))))}
