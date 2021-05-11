resource google_compute_region_instance_group_manager manager {
  count = local.is_regional_manager ? 1 : 0

  name = var.name
  base_instance_name = var.name
  region = var.location
  target_size = var.instance_count
  wait_for_instances = true

  update_policy {
    minimal_action = "REPLACE"
    type = "PROACTIVE"
    max_unavailable_fixed = var.instance_count
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

  version {
    instance_template = google_compute_instance_template.template.self_link
  }
}
