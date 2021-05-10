locals {
  // Boolean indicating whether or not we're creating a regional instance group manager.
  is_regional_manager = length(split("-", var.location)) == 2

  // Are we making use of CloudSQL?
  requires_cloudsql = length(var.cloudsql_connections) > 0

  // Extract just the timer names.
  timer_unit_names = formatlist("%s.timer", distinct(local.timers.*.name))

  // Format args as environment values.
  args = {
    for key, value in var.args:
      "ARG${key}" => value
  }

  // Format complete timer objects.
  timers = [
    for timer in var.timers: {
      name = timer.name
      schedule = timer.schedule
      args = {
        for key, value in lookup(timer, "args", []):
          "ARG${key}" => value
      }
    }
  ]

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
}
