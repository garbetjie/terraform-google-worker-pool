[Unit]
Requires=${join(" ", concat(["docker.service"], cloudsql ? ["cloudsql.service"] : []))}
After=${join(" ", concat(["docker.service"], cloudsql ? ["cloudsql.service"] : []))}

[Service]
Type=oneshot
Environment=HOME=/home/chronos
%{ for key, value in args }Environment=${key}=${value}
%{ endfor ~}
ExecStartPre=/usr/bin/docker-credential-gcr configure-docker
ExecStart=/usr/bin/docker run \
  --rm \
  --name=${name} \
  --env-file /home/chronos/.env \
  ${cloudsql ? "-v cloudsql:${cloudsql_path}:ro" : ""} \
  ${image} \
  ${join(" ", formatlist("$${%s}", keys(args)))}
ExecStop=/usr/bin/docker stop ${name}
