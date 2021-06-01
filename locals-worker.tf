locals {
  worker = {
    // TODO add restart policy, restart interval
    command = var.worker.command == null ? [] : var.worker.command
    env = var.worker.env == null ? {} : var.worker.env
    image = var.worker.image
    replicas = var.worker.replicas
    user = var.worker.user
    expose = var.worker.expose == null ? [] : [
      for expose in var.worker.expose: templatefile("${path.module}/parts/expose.tpl", { expose = expose })
    ]
    mounts = var.worker.mounts == null ? [] : [
      for mount in var.worker.mounts: templatefile("${path.module}/parts/mount.tpl", { mount = mount })
    ]
    init_commands = var.worker.init_commands == null ? [] : var.worker.init_commands
  }


  // Build worker arg file.
  worker_arg_file = var.systemd_name

  worker_arg_file_contents = join("\n", concat(
    [for index in range(length(local.worker.command)): format("ARG%d=%s", index, local.worker.command[index])],
    [""]
  ))


  // Build worker env file.
  worker_env_file = var.systemd_name

  worker_env_file_contents = join("\n", concat(
    [for k, v in local.worker.env: "${k}=${v}"],
    [""]
  ))


  // Build worker unit file.
  worker_unit_file = "${var.systemd_name}@.service"

  worker_unit_file_contents = templatefile("${path.module}/parts/service.tpl", {
    type = "exec"
    cloudsql_required = local.requires_cloudsql
    cloudsql_wait = local.wait_for_cloudsql
    arg_file = local.worker_arg_file
    pre_start = []
    stop = ""
    start = templatefile("${path.module}/parts/run.tpl", {
      name = "${var.systemd_name}-%i"
      env_file = var.systemd_name
      user = local.worker.user
      labels = { part-of = "worker" }
      mounts = concat(local.cloudsql_mounts, local.worker.mounts)
      expose = local.worker.expose
      image = local.worker.image
      command = local.worker.command
    })
  })
}