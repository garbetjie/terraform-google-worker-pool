variable workers {
  type = object({
    name = optional(string)
    command = optional(list(string))
    env = optional(map(string))
    image = string
    replicas = number
    user = optional(string)
    expose = optional(list(object({
      port = number
      protocol = optional(string)
      container_port = optional(number)
      host = optional(string)
    })))
    mounts = optional(list(object({
      name = string
      src = string
      target = string
      type = optional(string)
      readonly = optional(bool)
    })))
    init_commands = optional(list(object({
      command = list(string)
    })))
  })
}

locals {
  worker_name = var.workers.name == null ? "worker" : var.workers.name
  worker_command = var.workers.command == null ? [] : var.workers.command
  worker_env = var.workers.env == null ? {} : var.workers.env
  worker_image = var.workers.image
  worker_replicas = var.workers.replicas
  worker_user = var.workers.user
  worker_expose = var.workers.expose == null ? [] : [
    for expose in var.workers.expose: templatefile("${path.module}/templates/partial-expose.tpl", { expose = expose })
  ]
  worker_mounts = var.workers.mounts == null ? [] : [
    for mount in var.workers.mounts: templatefile("${path.module}/templates/partial-mount.tpl", { mount = mount })
  ]
  worker_init_commands = var.workers.init_commands == null ? [] : var.workers.init_commands
  
  // Build worker arg file.
  worker_arg_files = {
    (local.worker_name) = join("\n", concat(
      [for index in range(length(local.worker_command)): format("ARG%d=%s", index, local.worker_command[index])],
      [""]
    ))
  }

  // Build worker env file.
  worker_env_files = {
    (local.worker_name) = join("\n", concat(
      [for k, v in local.worker_env: "${k}=${v}"],
      [""]
    ))
  }

  // Build worker unit file.
  worker_unit_files = {
    "${local.worker_name}@.service" = templatefile("${path.module}/templates/systemd-service.tpl", {
      type = "exec"
      requires = local.cloudsql_provided_requires
      arg_file = keys(local.worker_arg_files)[0]
      exec_start_pre = local.cloudsql_provided_exec_start_pre
      exec_stop = templatefile("${path.module}/templates/docker-stop.tpl", { name = "${local.worker_name}-%i" })
      exec_start = templatefile("${path.module}/templates/docker-run.tpl", {
        name = "${local.worker_name}-%i"
        env_file = keys(local.worker_env_files)[0]
        user = local.worker_user
        labels = { part-of = "worker" }
        mounts = concat(local.cloudsql_provided_mounts, local.worker_mounts)
        expose = local.worker_expose
        image = local.worker_image
        command = local.worker_command
      })
    })
  }
}