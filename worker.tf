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
    name = string
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
  worker_expose_ports = [for p in var.expose_ports: {
    port = p.port
    protocol = lower(p.protocol == null ? "tcp" : p.protocol)
    container_port = p.container_port == null ? p.port : p.container_port
    host = p.host == null ? "0.0.0.0" : p.host
  }]
  worker_expose_ports_formatted = [
    for expose in local.worker_expose_ports: templatefile("${path.module}/templates/partial-expose.tpl", { expose = expose })
  ]
  worker_mounts = tolist([for m in var.mounts: {
    name = m.name
    src = m.src
    target = m.target
    type = lower(m.type == null ? "volume" : m.type)
    readonly = m.readonly == null ? false : m.readonly
  }])
  worker_mounts_formatted = [
    for mount in local.worker_mounts: templatefile("${path.module}/templates/partial-mount.tpl", { mount = mount })
  ]

  worker_init_commands = var.init_commands
  
  // Build worker arg file.
  worker_arg_files = {
    (local.worker_name) = join("\n", concat(
      [for index in range(length(var.command)): format("ARG%d=%s", index, var.command[index])],
      [""]
    ))
  }

  // Build worker env file.
  worker_env_files = {
    (local.worker_name) = join("\n", concat(
      [for k, v in var.env: "${k}=${v}"],
      [""]
    ))
  }

  // Build worker unit file.
  worker_unit_files = {
    "${local.worker_name}@.service" = templatefile("${path.module}/templates/systemd-service.tpl", {
      type = "exec"
      requires = local.cloudsql_provided_requires
      arg_file = keys(local.worker_arg_files)[0]
      exec_start_pre = concat(local.cloudsql_provided_exec_start_pre, [
        for index, command in local.worker_init_commands:
          templatefile("${path.module}/templates/docker-run.tpl", {
            name = "${local.worker_name}-%i-init-${format("%02d", index + 1)}"
            env_file = keys(local.worker_env_files)[0]
            user = var.user
            labels = { part-of = "worker-init" }
            mounts = concat(local.cloudsql_provided_mounts, local.worker_mounts_formatted)
            expose = []
            image = local.worker_image
            command = command
          })
      ])
      exec_stop = templatefile("${path.module}/templates/docker-stop.tpl", { name = "${local.worker_name}-%i" })
      exec_start = templatefile("${path.module}/templates/docker-run.tpl", {
        name = "${local.worker_name}-%i"
        env_file = keys(local.worker_env_files)[0]
        user = local.worker_user
        labels = { part-of = "worker" }
        mounts = concat(local.cloudsql_provided_mounts, local.worker_mounts_formatted)
        expose = local.worker_expose_ports_formatted
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