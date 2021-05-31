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
        [{
          path = "/etc/systemd/system/${var.systemd_name}@.service"
          permissions = "0644"
          content = templatefile("${path.module}/units/worker.tpl", {
            requires_cloudsql = local.requires_cloudsql
            wait_for_cloudsql = local.wait_for_cloudsql
            cloudsql_path = var.cloudsql_path
            image = var.image
            command = var.command
            systemd_name = var.systemd_name
            restart = var.restart_policy
            restart_sec = var.restart_interval
            expose_ports = local.expose_ports
            mounts = local.mounts
            user = var.user
          })
        }, {
          path = "/etc/runtime/env"
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
        }, {
          path = "/etc/runtime/args/worker"
          permissions = "0644"
          content = join("\n", concat([
            for index in range(length(var.command)):
              "${format("ARG%d", index)}=${var.command[index]}"
          ], [""]))
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

        // Create the timers.
        flatten([for timer in var.timers: [{
          path = "/etc/systemd/system/${timer.name}.timer"
          permissions = "0644"
          content = templatefile("${path.module}/units/timer.tpl", { timer = timer })
        }, {
          path = "/etc/runtime/args/timer-${timer.name}"
          permissions = "0644"
          content = join("\n", concat([
            for index in range(length(timer.command)):
              "${format("ARG%d", index)}=${timer.command[index]}"
          ], []))
        }]]),

        // Create the services for the timers.
        [for timer in local.timers: {
          path = "/etc/systemd/system/${timer.name}.service",
          permissions = "0644"
          content = templatefile("${path.module}/units/timer-service.tpl", {
            requires_cloudsql = local.requires_cloudsql
            wait_for_cloudsql = local.wait_for_cloudsql
            cloudsql_path = var.cloudsql_path
            image = var.image
            timer = timer
          })
        }],

        var.health_check_enabled ? [{
          path = "/etc/systemd/system/healthcheck.service"
          permissions = "0644"
          content = templatefile("${path.module}/units/healthcheck.service.tpl", {
            container_name = "healthcheck-${random_id.health_check_container_suffix.hex}",
            health_check_port = var.health_check_port
          })
        }, {
          path = "/tmp/scripts/healthcheck.sh"
          permissions = "0644"
          content = templatefile("${path.module}/scripts/healthcheck.sh.tpl", {
            expected_count = sum([var.workers_per_instance, local.requires_cloudsql ? 1 : 0])
          })
        }] : [],

        // Ensure script files are available.
        [{
          path = "/tmp/scripts/wait-for-cloudsql.sh"
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
        var.workers_per_instance > 0 ? ["systemctl start $(printf '${var.systemd_name}@%02d ' $(seq 1 ${var.workers_per_instance}))"] : [],
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
