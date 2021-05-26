locals {
  // Boolean indicating whether or not we're creating a regional instance group manager.
  is_regional_manager = length(split("-", var.location)) == 2

  // Are we making use of CloudSQL?
  requires_cloudsql = length(var.cloudsql_connections) > 0

  // Ensure the wait duration is formatted as a number.
  cloudsql_wait_duration = var.cloudsql_wait_duration == null ? -1 : var.cloudsql_wait_duration

  // Determine whether we should be waiting for CloudSQL or not.
  wait_for_cloudsql = local.requires_cloudsql && local.cloudsql_wait_duration > -1

  // The unique label used to target instances in firewall rules.
  tag = "${var.name}-${random_id.instance_tag_suffix.hex}"

  // Format complete timer objects.
  timers = [
    for timer in var.timers: {
      name = timer.name
      schedule = timer.schedule
      command = lookup(timer, "command", [])
    }
  ]

  // Determine the actual log options to use.
  log_opts = var.log_opts != null ? var.log_opts : lookup(local.default_log_opts, var.log_driver, {})

  // Default log options.
  default_log_opts = {
    json-file = {
      max-size = "50m"
      max-file = "10"
      compress = "true"
    }
    local = {
      max-size = "50m"
      max-file = "10"
      compress = "true"
    }
  }

  // Format the exposed ports.
  expose_ports = [
    for expose in var.expose_ports: {
      port = expose.port
      container_port = lookup(expose, "port", null) == null ? expose.port : expose.container_port
      protocol = lookup(expose, "protocol", null) == null ? "tcp" : expose.protocol
      host = lookup(expose, "host", null) == null ? "0.0.0.0" : expose.host
    }
  ]

  // Format the mounts.
  mounts = [
    for mount in var.mounts: {
      type = lookup(mount, "type", null) == null ? "volume" : mount.type
      src = mount.src
      target = mount.target
      readonly = lookup(mount, "readonly", null) == null ? false : mount.readonly
    }
  ]
}
