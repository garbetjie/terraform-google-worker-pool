output instance_group_manager_self_link {
  value = (
    local.is_regional_manager
      ? google_compute_region_instance_group_manager.manager[0].self_link
      : google_compute_instance_group_manager.manager[0].self_link
  )
}

output instance_group_self_link {
  value = (
    local.is_regional_manager
      ? google_compute_region_instance_group_manager.manager[0].instance_group
      : google_compute_instance_group_manager.manager[0].instance_group
  )
}

output instance_template_self_link {
  value = google_compute_instance_template.template.self_link
}

output regional {
  value = local.is_regional_manager
}

output tag {
  value = local.tag
}

output name {
  value = var.name
}

output location {
  value = var.location
}

output metadata {
  value = google_compute_instance_template.template.metadata
}

output disk_size {
  value = var.disk_size
}

output disk_type {
  value = var.disk_type
}

output instance_count {
  value = var.instance_count
}

output labels {
  value = var.labels
}

output machine_type {
  value = var.machine_type
}

output network {
  value = var.network
}

output preemptible {
  value = var.preemptible
}

output restart_interval {
  value = var.restart_interval
}

output restart_policy {
  value = var.restart_policy
}

output runcmd {
  value = var.runcmd
}

output service_account_email {
  value = var.service_account_email
}

output tags {
  value = var.tags
}

output timers {
  value = var.timers
}

output timezone {
  value = var.timezone
}

output wait_for_instances {
  value = var.wait_for_instances
}