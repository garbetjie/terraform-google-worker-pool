${jsonencode({
    host = coalesce(host, "0.0.0.0")
    port = port
    container_port = coalesce(container_port, port)
    protocol = lower(coalesce(protocol, "tcp"))
})}