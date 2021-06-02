resource google_compute_instance_template template {
  name_prefix = "${var.name}-"
  machine_type = var.machine_type
  labels = var.labels
  tags = distinct(concat(var.tags, [local.tag]))

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

  metadata = merge(var.metadata, {
    user-data = join("\n", ["#cloud-config", yamlencode({
      write_files = concat(
        [
          { path = "/etc/docker/daemon.json", permissions = "0644", content = local.docker_config_contents },
        ],

        // Populate systemd unit files.
        [for file, content in merge(local.unit_files_workers, local.unit_files_timers, local.unit_files_cloudsql, local.unit_files_health_check):
          { path = "/etc/systemd/system/${file}", permissions = "0644", content = content }
        ],

        // Populate arg files.
        [for file, content in merge(local.arg_files_workers, local.arg_files_timers):
          { path = "/etc/runtime/args/${file}", permissions = "0644", content = content }
        ],

        // Populate env files.
        [for file, content in merge(local.env_files_workers, local.env_files_timers):
          { path = "/etc/runtime/envs/${file}", permissions = "0644", content = content }
        ],

        // Populate script files.
        [for file, content in merge(local.script_files_cloudsql, local.script_files_health_check):
          { path = "/etc/runtime/scripts/${file}", permissions = "0644", content = content }
        ],
      ),

      runcmd = concat(
        ["rm -f /etc/localtime", "ln -s /usr/share/zoneinfo/${var.timezone} /etc/localtime"],
        ["systemctl daemon-reload", "systemctl restart docker"],
        ["HOME=/etc/runtime docker-credential-gcr configure-docker"],
        var.runcmd,
        local.workers.replicas > 0 ? ["systemctl start $(printf '${local.workers.name}@%02d ' $(seq 1 ${local.workers.replicas}))"] : [],
        length(local.timers) > 0 ? ["systemctl start ${join(" ", formatlist("%s.timer", distinct(local.timers.*.name)))}"]: [],
        local.health_check_enabled ? ["systemctl start ${keys(local.unit_files_health_check)[0]}"] : [],
      )
    })])
  })

  scheduling {
    preemptible = var.preemptible
    automatic_restart = !var.preemptible
  }

  lifecycle {
    create_before_destroy = true
  }
}
