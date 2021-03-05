resource google_compute_instance_template template {
  name_prefix = "${var.name}-"
  machine_type = var.machine_type
  labels = var.labels

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

  metadata = {
    user-data = "#cloud-config\n${yamlencode(local.cloudinit_config)}"
  }

  scheduling {
    preemptible = var.preemptible
    automatic_restart = !var.preemptible
  }

  lifecycle {
    create_before_destroy = true
  }
}

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

  version {
    instance_template = google_compute_instance_template.template.self_link
  }
}
