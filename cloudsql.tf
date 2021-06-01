variable cloudsql_connections {
  type = set(string)
  default = []
  description = "List of CloudSQL connections to establish before starting workers."
}

variable cloudsql_path {
  type = string
  default = "/cloudsql"
  description = "The path at which CloudSQL connection sockets will be available in workers and timers."
}

variable cloudsql_restart_interval {
  type = number
  default = 5
  description = "Number of seconds to wait before restarting the CloudSQL service if it stops."
}

variable cloudsql_restart_policy {
  type = string
  default = "always"
  description = "The restart policy to apply to the CloudSQL service."

  validation {
    condition = contains(["no", "on-success", "on-failure", "on-abnormal", "on-watchdog", "on-abort", "always"], var.cloudsql_restart_policy)
    error_message = "CloudSQL restart policy must be one of [always, no, on-success, on-failure, on-abnormal, on-watchdog, on-abort]."
  }
}

variable cloudsql_wait_duration {
  type = number
  default = 30
  description = "How long to wait (in seconds) for CloudSQL connections to be established before starting workers."
}

variable cloudsql {
  type = object({
    connections = set(string)
    mount_path = string
    restart_interval = number
    restart_policy = string
    wait_duration = number
  })
}

locals {
  cloudsql_connections = var.cloudsql.connections
  cloudsql_mount_name = "cloudsql"
  cloudsql_mount_path = var.cloudsql.mount_path == null ? "/cloudsql" : var.cloudsql.mount_path
  cloudsql_restart_policy = var.cloudsql.restart_policy == null ? "always" : var.cloudsql.restart_policy
  cloudsql_restart_interval = var.cloudsql.restart_interval == null ? 5 : var.cloudsql.restart_interval
  cloudsql_wait_duration = var.cloudsql_wait_duration == null ? -1 : var.cloudsql_wait_duration

  cloudsql_required = length(var.cloudsql_connections) > 0
  cloudsql_wait = local.cloudsql_required && var.cloudsql_wait_duration >= 0

  cloudsql_provided_exec_start_pre = local.cloudsql_wait ? ["/bin/sh /etc/runtime/scripts/wait-for-cloudsql.sh"] : []
  cloudsql_provided_requires = local.cloudsql_required ? ["cloudsql.service"] : []
  cloudsql_provided_mounts = !local.cloudsql_required ? [] : [templatefile("${path.module}/partials/mount.tpl", {
    mount = { type = "volume", src = local.cloudsql_mount_name, target = var.cloudsql_path, readonly = true }
  })]

  cloudsql_unit_files = local.cloudsql_required ? {
    "cloudsql.service" = templatefile("${path.module}/templates/systemd-cloudsql.tpl", {
      connections = var.cloudsql_connections
      mount_name = local.cloudsql_mount_name
      restart = var.cloudsql_restart_policy
      restart_sec = var.cloudsql_restart_interval
    })
  } : {}
}