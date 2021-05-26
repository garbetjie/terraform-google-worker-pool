[Unit]
Requires=docker.service
After=docker.service

[Service]
Type=exec
Environment=HOME=/etc/runtime
Environment=container_name=${container_name}
ExecStartPre=/usr/bin/docker create --name $${container_name} -p ${health_check_port}:8080 alpine:3.13 nc -lk -p 8080 -e /bin/sh -c 'echo OK'
ExecStart=/bin/sh /tmp/scripts/healthcheck.sh
ExecStopPost=/usr/bin/docker rm $${container_name}
