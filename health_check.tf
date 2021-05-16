resource google_compute_health_check instance_health {
  count = var.health_check_enabled ? 1 : 0
  name = var.health_check_name == null ? "${var.name}-healthy" : var.health_check_name
  check_interval_sec = var.health_check_interval
  timeout_sec = 1
  healthy_threshold = var.health_check_healthy_threshold
  unhealthy_threshold = var.health_check_unhealthy_threshold

  tcp_health_check {
    port = var.health_check_port
  }
}

resource google_compute_firewall instance_health_checks {
  count = var.health_check_enabled ? 1 : 0
  name = google_compute_health_check.instance_health[0].name
  network = var.network
  source_ranges = ["35.191.0.0/16", "130.211.0.0/22"]
  target_tags = [local.target_label]

  allow {
    protocol = "TCP"
    ports = [var.health_check_port]
  }
}