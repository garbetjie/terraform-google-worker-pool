locals {
  // Boolean indicating whether or not we're creating a regional instance group manager.
  is_regional_manager = length(split("-", var.location)) == 2

  // The unique label used to target instances in firewall rules.
  tag = "${var.name}-${random_id.instance_tag_suffix.hex}"

  // Build docker config.
  docker_config_contents = jsonencode({ log-driver = local.logging_driver, log-opts = local.logging_options })
}
