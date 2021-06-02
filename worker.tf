variable command {
  type = list(string)
  default = []
}

variable env {
  type = map(string)
  default = {}
}

variable image {
  type = string
}

variable workers_per_instance {
  type = number
  default = 3
}

variable user {
  type = string
  default = null
}

variable expose_ports {
  type = list(object({
    port = number
    protocol = optional(string)
    container_port = optional(number)
    host = optional(string)
  }))
  default = []
}

variable mounts {
  type = list(object({
    src = string
    target = string
    type = optional(string)
    readonly = optional(bool)
  }))
  default = []
}

variable init_commands {
  type = list(object({ command = list(string) }))
  default = []
}

variable worker_name {
  type = string
  default = "worker"
}

locals {
  worker_name = var.worker_name
  worker_command = var.command
  worker_env = var.env
  worker_image = var.image
  worker_replicas = var.workers_per_instance
  worker_user = var.user
  worker_expose_ports = [for e in var.expose_ports: templatefile("${path.module}/templates/expose.json.tpl", e)]
  worker_mounts = [for m in var.mounts: jsondecode(templatefile("${path.module}/templates/mount.json.tpl", m))]

  worker_init_commands = var.init_commands
  
  // Build worker arg file.
  arg_files_workers = {
    (local.worker_name) = join("\n", concat(
      [for index in range(length(var.command)): format("ARG%d=%s", index, var.command[index])],
      [""]
    ))
  }

  // Build worker env file.
  env_files_workers = {
    (local.worker_name) = join("\n", concat(
      [for k, v in var.env: "${k}=${v}"],
      [""]
    ))
  }

  // Build worker unit file.
  unit_files_workers = {
    "${local.worker_name}@.service" = templatefile("${path.module}/templates/systemd-service.tpl", {
      type = "exec"
      requires = local.cloudsql_systemd_requires
      arg_file = keys(local.arg_files_workers)[0]
      exec_start_pre = concat(local.cloudsql_system_exec_start_pre, [
        for index, command in local.worker_init_commands:
          templatefile("${path.module}/templates/docker-run.tpl", {
            name = "${local.worker_name}-%i-init-${format("%02d", index + 1)}"
            env_file = keys(local.env_files_workers)[0]
            user = var.user
            labels = { part-of = "worker-init" }
            mounts = concat(local.cloudsql_mounts, local.worker_mounts)
            expose = []
            image = local.worker_image
            command = command
          })
      ])
      exec_stop = templatefile("${path.module}/templates/docker-stop.tpl", { name = "${local.worker_name}-%i" })
      exec_start = templatefile("${path.module}/templates/docker-run.tpl", {
        name = "${local.worker_name}-%i"
        env_file = keys(local.env_files_workers)[0]
        user = local.worker_user
        labels = { part-of = "worker" }
        mounts = concat(local.cloudsql_mounts, local.worker_mounts)
        expose = local.worker_expose_ports
        image = local.worker_image
        command = local.worker_command
      })
    })
  }
}

output worker_name {
  value = local.worker_name
}

output env {
  value = local.worker_env
}

output image {
  value = local.worker_image
}

output workers_per_instance {
  value = local.worker_replicas
}

output user {
  value = local.worker_user
}

output expose_ports {
  value = local.worker_expose_ports
}

output mounts {
  value = local.worker_mounts
}

output init_commands {
  value = local.worker_init_commands
}