variable cloudsql_connections {
  type = set(string)
  default = []
  description = "List of CloudSQL connections to establish before starting workers."
}

variable cloudsql_mount_path {
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

locals {
  cloudsql_connections = var.cloudsql_connections
  cloudsql_mount_name = "cloudsql"
  cloudsql_mount_path = var.cloudsql_mount_path
  cloudsql_restart_policy = var.cloudsql_restart_policy
  cloudsql_restart_interval = var.cloudsql_restart_interval
  cloudsql_wait_duration = var.cloudsql_wait_duration

  cloudsql_required = length(local.cloudsql_connections) > 0
  cloudsql_wait = local.cloudsql_required && local.cloudsql_wait_duration >= 0

  cloudsql_provided_exec_start_pre = local.cloudsql_wait ? ["/bin/sh /etc/runtime/scripts/wait-for-cloudsql.sh"] : []
  cloudsql_provided_requires = local.cloudsql_required ? ["cloudsql.service"] : []
  cloudsql_provided_mounts = !local.cloudsql_required ? [] : [templatefile("${path.module}/templates/partial-mount.tpl", {
    mount = { type = "volume", src = local.cloudsql_mount_name, target = local.cloudsql_mount_path, readonly = true }
  })]

  cloudsql_unit_files = local.cloudsql_required ? {
    "cloudsql.service" = templatefile("${path.module}/templates/systemd-cloudsql.tpl", {
      connections = local.cloudsql_connections
      mount_name = local.cloudsql_mount_name
      restart = local.cloudsql_restart_policy
      restart_sec = local.cloudsql_restart_interval
    })
  } : {}

  cloudsql_script_files = local.cloudsql_wait ? {
    "wait-for-cloudsql.sh" = templatefile("${path.module}/templates/script-wait-for-cloudsql.sh.tpl", {
      wait_duration = local.cloudsql_wait_duration
    })
  } : {}
}

output cloudsql_connections {
  value = local.cloudsql_connections
}

output cloudsql_mount_path {
  value = local.cloudsql_mount_path
}

output cloudsql_restart_policy {
  value = local.cloudsql_restart_policy
}

output cloudsql_restart_interval {
  value = local.cloudsql_restart_interval
}

output cloudsql_wait_duration {
  value = local.cloudsql_wait_duration
}

output cloudsql_wait {
  value = local.cloudsql_wait
}