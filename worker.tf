variable worker {
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
  worker_name = var.worker.name == null ? "worker" : var.worker.name
  worker_command = var.worker.command == null ? [] : var.worker.command
  worker_env = var.worker.env == null ? {} : var.worker.env
  worker_image = var.worker.image
  worker_replicas = var.worker.replicas
  worker_user = var.worker.user
  worker_expose = var.worker.expose == null ? [] : [
    for expose in var.worker.expose: templatefile("${path.module}/templates/partial-expose.tpl", { expose = expose })
  ]
  worker_mounts = var.worker.mounts == null ? [] : [
    for mount in var.worker.mounts: templatefile("${path.module}/templates/partial-mount.tpl", { mount = mount })
  ]
  init_commands = var.worker.init_commands == null ? [] : var.worker.init_commands
  
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