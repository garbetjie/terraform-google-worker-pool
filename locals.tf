locals {
  is_regional_manager = length(split("-", var.location)) == 2

  has_environment = length(var.env) > 0

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

  cloudinit_config = {
    write_files = concat(
      [{
        path = "/etc/systemd/system/worker@.service"
        permissions = "0644"
        content = templatefile("${path.module}/systemd-worker.tpl", {
          cloudsql = length(var.cloudsql_connections) > 0,
          cloudsql_path = var.cloudsql_path
          image = var.image
          args = var.args
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
      length(var.cloudsql_connections) > 0 ? [{
        path = "/etc/systemd/system/cloudsql.service"
        permissions = "0644"
        content = templatefile("${path.module}/systemd-cloudsql.tpl", { connections = var.cloudsql_connections })
      }] : []
    ),

    runcmd = [
      "systemctl daemon-reload",
      "systemctl restart docker",
      "systemctl start $(printf 'worker@%02d ' $(seq 1 ${var.workers_per_instance}))"
    ]
  }
}
