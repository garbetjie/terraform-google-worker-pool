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

output name {
  value = var.name
}

output image {
  value = var.image
}

output location {
  value = var.location
}

output workers_per_instance {
  value = var.workers_per_instance
}

output command {
  value = var.command
}

output cloudsql_connections {
  value = var.cloudsql_connections
}

output cloudsql_path {
  value = var.cloudsql_path
}

output disk_size {
  value = var.disk_size
}

output disk_type {
  value = var.disk_type
}

output env {
  value = var.env
}

output instance_count {
  value = var.instance_count
}

output labels {
  value = var.labels
}

output log_driver {
  value = var.log_driver
}

output log_opts {
  value = var.log_opts
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

output service_account_email {
  value = var.service_account_email
}

output systemd_name {
  value = var.systemd_name
}

output timers {
  value = var.timers
}