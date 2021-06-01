locals {
  // Boolean indicating whether or not we're creating a regional instance group manager.
  is_regional_manager = length(split("-", var.location)) == 2

//  // Are we making use of CloudSQL?
//  requires_cloudsql = length(var.cloudsql_connections) > 0

//  // Ensure the wait duration is formatted as a number.
//  cloudsql_wait_duration = var.cloudsql_wait_duration == null ? -1 : var.cloudsql_wait_duration
//
//  // Determine whether we should be waiting for CloudSQL or not.
//  wait_for_cloudsql = local.requires_cloudsql && local.cloudsql_wait_duration > -1

  // The unique label used to target instances in firewall rules.
  tag = "${var.name}-${random_id.instance_tag_suffix.hex}"

  // Determine the actual log options to use.
  log_opts = var.log_opts != null ? var.log_opts : lookup(local.default_log_opts, var.log_driver, {})

  // Default log options.
  default_log_opts = {
    json-file = {
      max-size = "50m"
      max-file = "10"
      compress = "true"
    }
    local = {
      max-size = "50m"
      max-file = "10"
      compress = "true"
    }
  }

//  cloudsql_mounts = local.requires_cloudsql ? [templatefile("${path.module}/parts/mount.tpl", {
//    mount = {
//      type = "volume"
//      src = "cloudsql"
//      target = var.cloudsql_path
//      readonly = true
//    }
//  })] : []
//
//  cloudsql_pre_start = local.wait_for_cloudsql ? ["/bin/sh /etc/runtime/scripts/wait-for-cloudsql.sh"] : []

  // Build docker config.
  docker_config_contents = jsonencode({ log-driver = var.log_driver, log-opts = local.log_opts })
}
