resource google_compute_instance_template template {
  name_prefix = "${var.name}-"
  machine_type = var.machine_type
  labels = var.labels

  dynamic service_account {
    for_each = var.service_account_email != null ? [var.service_account_email] : []
    content {
      scopes = ["cloud-platform"]
      email = service_account.value
    }
  }

  disk {
    disk_size_gb = var.disk_size
    disk_type = var.disk_type
    source_image = "cos-cloud/cos-stable"
    auto_delete = true
  }

  network_interface {
    network = var.network
  }

  metadata = {
    user-data = join("\n", ["#cloud-config", yamlencode({
      write_files = concat(
        [{
          path = "/etc/systemd/system/${var.systemd_name}@.service"
          permissions = "0644"
          content = templatefile("${path.module}/templates/worker.tpl", {
            requires_cloudsql = local.requires_cloudsql,
            cloudsql_path = var.cloudsql_path
            image = var.image
            args = local.args
            systemd_name = var.systemd_name
          })
        }, {
          path = "/home/chronos/.env"
          permissions = "0644"
          owner = "chronos:chronos"
          content = join("\n", concat(
            [for key, value in var.env: "${key}=${value}"],
            [""]
          ))
        }, {
          path = "/etc/docker/daemon.json",
          permissions = "0644"
          content = jsonencode({
            log-driver = var.log_driver,
            log-opts = local.log_opts
          })
        }],

        // Create the CloudSQL service.
        local.requires_cloudsql ? [{
          path = "/etc/systemd/system/cloudsql.service"
          permissions = "0644"
          content = templatefile("${path.module}/templates/cloudsql.tpl", { connections = var.cloudsql_connections })
        }] : [],

        // Create the timers.
        [for timer in var.timers: {
          path = "/etc/systemd/system/${timer.name}.timer"
          permissions = "0644"
          content = templatefile("${path.module}/templates/timer.tpl", { timer = timer })
        }],

        // Create the services for the timers.
        [for timer in local.timers: {
          path = "/etc/systemd/system/${timer.name}.service",
          permissions = "0644"
          content = templatefile("${path.module}/templates/timer-service.tpl", {
            requires_cloudsql = local.requires_cloudsql
            cloudsql_path = var.cloudsql_path
            image = var.image
            timer = timer
          })
        }]
      ),

      runcmd = concat(
        ["systemctl daemon-reload", "systemctl restart docker"],
        var.workers_per_instance > 0 ? ["systemctl start $(printf '${var.systemd_name}@%02d ' $(seq 1 ${var.workers_per_instance}))"] : [],
        length(local.timer_unit_names) > 0 ? ["systemctl start ${join(" ", local.timer_unit_names)}"]: []
      )
    })])
  }

  scheduling {
    preemptible = var.preemptible
    automatic_restart = !var.preemptible
  }

  lifecycle {
    create_before_destroy = true
  }
}
