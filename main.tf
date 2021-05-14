resource google_compute_region_instance_group_manager manager {
  count = local.is_regional_manager ? 1 : 0

  name = var.name
  base_instance_name = var.name
  region = var.location
  target_size = var.instance_count
  wait_for_instances = true
  distribution_policy_zones = data.google_compute_zones.regional_zones[0].names

  update_policy {
    minimal_action = "REPLACE"
    type = "PROACTIVE"
    max_unavailable_fixed = max(var.instance_count, length(data.google_compute_zones.regional_zones[0].names))
  }

  dynamic "auto_healing_policies" {
    for_each = var.health_check_enabled ? [google_compute_health_check.instance_health.self_link] : []

    content {
      health_check = auto_healing_policies.value
      initial_delay_sec = var.health_check_initial_delay
    }
  }

  version {
    instance_template = google_compute_instance_template.template.self_link
  }
}

resource google_compute_instance_group_manager manager {
  count = local.is_regional_manager ? 0 : 1

  name = var.name
  base_instance_name = var.name
  zone = var.location
  target_size = var.instance_count
  wait_for_instances = true

  update_policy {
    minimal_action = "REPLACE"
    type = "PROACTIVE"
    max_unavailable_fixed = var.instance_count
  }

  dynamic "auto_healing_policies" {
    for_each = var.health_check_enabled ? [google_compute_health_check.instance_health.self_link] : []

    content {
      health_check = auto_healing_policies.value
      initial_delay_sec = var.health_check_initial_delay
    }
  }

  version {
    instance_template = google_compute_instance_template.template.self_link
  }
}
