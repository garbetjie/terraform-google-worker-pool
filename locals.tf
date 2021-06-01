locals {
  // Boolean indicating whether or not we're creating a regional instance group manager.
  is_regional_manager = length(split("-", var.location)) == 2

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

  // Build docker config.
  docker_config_contents = jsonencode({ log-driver = var.log_driver, log-opts = local.log_opts })
}
