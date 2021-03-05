output regional_manager_self_link {
  value = count(google_compute_region_instance_group_manager.manager) > 0 ? google_compute_region_instance_group_manager.manager[0].self_link : null
}

output zonal_manager_self_link {
  value = count(google_compute_instance_group_manager.manager) > 0 ? google_compute_instance_group_manager.manager[0].self_link : null
}

output instance_template_self_link {
  value = google_compute_instance_template.template.self_link
}
