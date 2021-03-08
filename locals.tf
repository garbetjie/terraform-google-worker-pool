locals {
  // Boolean indicating whether or not we're creating a regional instance group manager.
  is_regional_manager = length(split("-", var.location)) == 2

  // Are we making use of CloudSQL?
  has_cloudsql = length(var.cloudsql_connections) > 0

  // Extract just the timer names.
  timer_unit_names = distinct([for timer in var.timers: "${timer.name}.timer"])

  // Default log options.
  default_log_opts = {
    json-file = {
      max-size = "50m"
      max-file = "5"
      compress = "true"
    }
    local = {
      max-size = "50m"
      max-file = "5"
      compress = "true"
    }
  }

  // cloud-init config.
  cloudinit_config = {
    write_files = concat(
      [{
        path = "/etc/systemd/system/worker@.service"
        permissions = "0644"
        content = templatefile("${path.module}/systemd-worker.tpl", {
          cloudsql = local.has_cloudsql,
          cloudsql_path = var.cloudsql_path
          image = var.image
          args = var.args
          prefix = var.worker_name_prefix
        })
      }, {
        path = "/home/chronos/.env"
        permissions = "0644"
        owner = "chronos:chronos"
        content = join("\n", concat([
          for key, value in var.env:
            "${key}=${value}"
        ], [""]))
      }, {
        path = "/etc/docker/daemon.json",
        permissions = "0644"
        content = jsonencode({
          log-driver = var.log_driver,
          log-opts = var.log_opts != null ? var.log_opts : lookup(local.default_log_opts, var.log_driver, {})
        })
      }],

      // Create the CloudSQL service.
      local.has_cloudsql ? [{
        path = "/etc/systemd/system/cloudsql.service"
        permissions = "0644"
        content = templatefile("${path.module}/systemd-cloudsql.tpl", { connections = var.cloudsql_connections })
      }] : [],

      // Create the timers.
      [for timer in var.timers: {
        path = "/etc/systemd/system/${timer.name}.timer"
        permissions = "0644"
        content = templatefile("${path.module}/systemd-timer.tpl", {
          name = timer.name
          schedule = timer.schedule
        })
      }],

      // Create the services for the timers.
      [for timer in var.timers: {
        path = "/etc/systemd/system/${timer.name}.service",
        permissions = "0644"
        content = templatefile("${path.module}/systemd-timer-service.tpl", {
          cloudsql = local.has_cloudsql
          cloudsql_path = var.cloudsql_path
          name = timer.name
          image = var.image
          args = timer.args
        })
      }]
    ),

    runcmd = concat(
      [
        "systemctl daemon-reload",
        "systemctl restart docker",
        "systemctl start $(printf 'worker@%02d ' $(seq 1 ${var.workers_per_instance}))"
      ],
      length(local.timer_unit_names) > 0 ? ["systemctl start ${join(" ", local.timer_unit_names)}"]: []
    )
  }
}
