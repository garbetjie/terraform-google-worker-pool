locals {
  is_regional_manager = length(split("-", var.location)) == 2

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
