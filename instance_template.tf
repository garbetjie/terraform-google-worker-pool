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
          // Set docker config.
          { path = "/etc/docker/daemon.json", permissions = "0644", content = local.docker_config_contents },

          // Populate worker files.
          { path = "/etc/runtime/args/${local.worker_arg_file}", permissions = "0644", content = local.worker_arg_file_contents },
          { path = "/etc/runtime/envs/${local.worker_env_file}", permissions = "0644", content = local.worker_env_file_contents },
          { path = "/etc/systemd/system/${local.worker_unit_file}", permissions = "0644", content = local.worker_unit_file_contents },
        ],

        // Populate timer files.
        [for file, contents in local.timer_arg_file_contents: {
          path = "/etc/runtime/args/${file}", permissions = "0644", content = contents
        }],
        [for file, contents in local.timer_env_file_contents: {
          path = "/etc/runtime/envs/${file}", permissions = "0644", content = contents
        }],
        [for file, contents in local.timer_unit_file_contents: {
          path = "/etc/systemd/system/${file}", permissions = "0644", content = contents
        }],

        // Create the CloudSQL service.
        local.requires_cloudsql ? [{
          path = "/etc/systemd/system/cloudsql.service"
          permissions = "0644"
          content = templatefile("${path.module}/units/cloudsql.tpl", {
            connections = var.cloudsql_connections
            restart_sec = var.cloudsql_restart_interval
            restart = var.cloudsql_restart_policy
          })
        }] : [],

        var.health_check_enabled ? [{
          path = "/etc/systemd/system/healthcheck.service"
          permissions = "0644"
          content = templatefile("${path.module}/units/healthcheck.service.tpl", {
            container_name = "healthcheck-${random_id.health_check_container_suffix.hex}",
            health_check_port = var.health_check_port
          })
        }, {
          path = "/etc/runtime/scripts/healthcheck.sh"
          permissions = "0644"
          content = templatefile("${path.module}/scripts/healthcheck.sh.tpl", {
            expected_count = sum([local.worker.replicas, local.requires_cloudsql ? 1 : 0])
          })
        }] : [],

        // Ensure script files are available.
        [{
          path = "/etc/runtime/scripts/wait-for-cloudsql.sh"
          permissions = "0644"
          content = templatefile("${path.module}/scripts/wait-for-cloudsql.sh.tpl", {
            wait_duration = local.cloudsql_wait_duration
          })
        }]
      ),

      runcmd = concat(
        ["rm -f /etc/localtime", "ln -s /usr/share/zoneinfo/${var.timezone} /etc/localtime"],
        ["systemctl daemon-reload", "systemctl restart docker"],
        ["HOME=/etc/runtime docker-credential-gcr configure-docker"],
        var.runcmd,
        local.worker.replicas > 0 ? ["systemctl start $(printf '${var.systemd_name}@%02d ' $(seq 1 ${local.worker.replicas}))"] : [],
        length(local.timers) > 0 ? ["systemctl start ${join(" ", formatlist("%s.timer", distinct(local.timers.*.name)))}"]: [],
        var.health_check_enabled ? ["systemctl start healthcheck"] : [],
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
