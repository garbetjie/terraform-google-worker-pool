variable cloudsql {
  type = object({
    connections = set(string)
    wait_duration = optional(number)
    mount_name = optional(string)
    mount_path = optional(string)
    restart_policy = optional(string)  // ["no", "on-success", "on-failure", "on-abnormal", "on-watchdog", "on-abort", "always"]
    restart_interval = optional(number)
  })

  default = {
    connections = []
    wait_duration = 30
    mount_name = "cloudsql"
    mount_path = "/cloudsql"
    restart_policy = "always"
    restart_interval = 5
  }
}

locals {
  cloudsql = {
    connections = var.cloudsql.connections
    wait_duration = var.cloudsql.wait_duration == null ? 30 : var.cloudsql.wait_duration
    mount_name = coalesce(var.cloudsql.mount_name, "cloudsql")
    mount_path = coalesce(var.cloudsql.mount_path, "/cloudsql")
    restart_policy = coalesce(var.cloudsql.restart_policy, "always")
    restart_interval = coalesce(var.cloudsql.restart_interval, 5)
  }

  cloudsql_required = length(local.cloudsql.connections) > 0
  cloudsql_wait = local.cloudsql_required && local.cloudsql.wait_duration >= 0

  cloudsql_systemd_exec_start_pre = local.cloudsql_wait ? ["/bin/sh /etc/runtime/scripts/wait-for-cloudsql.sh"] : []
  cloudsql_systemd_requires = local.cloudsql_required ? ["cloudsql.service"] : []

  cloudsql_mounts = local.cloudsql_required ? [
    jsondecode(
      templatefile("${path.module}/templates/mount.json.tpl", {
        type = "volume",
        src = local.cloudsql.mount_name,
        target = local.cloudsql.mount_path,
        readonly = true
      })
    )
  ] : []

  // Unit files to be included in the cloud-init config.
  unit_files_cloudsql = local.cloudsql_required ? {
    "cloudsql.service" = templatefile("${path.module}/templates/systemd-cloudsql.tpl", {
      connections = local.cloudsql.connections
      mount_name = local.cloudsql.mount_name
      restart = local.cloudsql.restart_policy
      restart_sec = local.cloudsql.restart_interval
    })
  } : {}

  // Script files to be included in the cloud-init config.
  script_files_cloudsql = local.cloudsql_wait ? {
    "wait-for-cloudsql.sh" = templatefile("${path.module}/templates/script-wait-for-cloudsql.sh.tpl", {
      wait_duration = local.cloudsql.wait_duration
    })
  } : {}
}

output cloudsql {
  value = {
    connections = local.cloudsql.connections
    wait_duration = local.cloudsql.wait_duration
    mount_name = local.cloudsql.mount_name
    mount_path = local.cloudsql.mount_path
    restart_policy = local.cloudsql.restart_policy
    restart_interval = local.cloudsql.restart_interval
  }
}

output cloudsql_wait {
  value = local.cloudsql_wait
}