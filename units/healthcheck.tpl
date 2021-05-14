[Unit]
Requires=docker.service
After=docker.service

[Service]
Type=exec
Environment=HOME=/home/chronos
ExecStart=/bin/sh /tmp/scripts/healthcheck.sh
