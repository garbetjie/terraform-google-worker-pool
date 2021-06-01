variable health_check {
  type = object({
    enabled = bool
    port = optional(number)
    name = optional(string)
    interval = optional(number)
    healthy_threshold = optional(number)
    unhealthy_threshold = optional(number)
    initial_delay = optional(number)
  })
  default = {
    enabled = false
  }
}

locals {
  health_check_enabled = var.health_check.enabled
  health_check_port = var.health_check.port == null ? 4144 : var.health_check.port
  health_check_name = var.health_check.name == null ? "${var.name}-healthy" : var.health_check.name
  health_check_interval = var.health_check.interval == null ? 10 : var.health_check.interval
  health_check_healthy_threshold = var.health_check.healthy_threshold == null ? 3 : var.health_check.healthy_threshold
  health_check_unhealthy_threshold = var.health_check.unhealthy_threshold == null ? 3 : var.health_check.unhealthy_threshold
  health_check_initial_delay = var.health_check.initial_delay == null ? 60 : var.health_check.initial_delay

  health_check_unit_files = ! local.health_check_enabled ? {} : {
    "healthcheck.service" = templatefile("${path.module}/templates/systemd-healthcheck.tpl", {
      container_name = "healthcheck-${random_id.health_check_container_suffix.hex}",
      health_check_port = local.health_check_port
    })
  }

  health_check_script_files = ! local.health_check_enabled ? {} : {
    "healthcheck.sh" = templatefile("${path.module}/templates/script-healthcheck.sh.tpl", {
      expected_count = sum([local.worker_replicas, local.cloudsql_required ? 1 : 0])
    })
  }
}

resource random_id health_check_container_suffix {
  byte_length = 4
}

resource google_compute_health_check instance_health {
  count = local.health_check_enabled ? 1 : 0
  name = local.health_check_name
  check_interval_sec = local.health_check_interval
  timeout_sec = 1
  healthy_threshold = local.health_check_healthy_threshold
  unhealthy_threshold = local.health_check_unhealthy_threshold

  tcp_health_check {
    port = local.health_check_port
  }
}

resource google_compute_firewall instance_health_checks {
  count = local.health_check_enabled ? 1 : 0
  name = google_compute_health_check.instance_health[0].name
  network = var.network
  source_ranges = ["35.191.0.0/16", "130.211.0.0/22"]
  target_tags = [local.tag]

  allow {
    protocol = "TCP"
    ports = [local.health_check_port]
  }
}