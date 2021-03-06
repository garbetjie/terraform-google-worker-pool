locals {
  is_regional_manager = length(split("-", var.location)) == 2

  has_environment = length(var.env) > 0

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
      }],
      length(var.cloudsql_connections) > 0 ? [{
        path = "/etc/systemd/system/cloudsql.service"
        permissions = "0644"
        content = templatefile("${path.module}/systemd-cloudsql.tpl", { connections = var.cloudsql_connections })
      }] : []
    ),

    runcmd = [
      "systemctl daemon-reload",
      "systemctl start $(printf 'worker@%02d ' $(seq 1 ${var.workers_per_instance}))"
    ]
  }
}
