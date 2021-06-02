//variable command {
//  type = list(string)
//  default = []
//}
//
//variable env {
//  type = map(string)
//  default = {}
//}
//
//variable image {
//  type = string
//}
//
//variable workers_per_instance {
//  type = number
//  default = 3
//}
//
//variable user {
//  type = string
//  default = null
//}
//
//variable expose_ports {
//  type = list(object({
//    port = number
//    protocol = optional(string)
//    container_port = optional(number)
//    host = optional(string)
//  }))
//  default = []
//}
//
//variable mounts {
//  type = list(object({
//    src = string
//    target = string
//    type = optional(string)
//    readonly = optional(bool)
//  }))
//  default = []
//}
//
//variable init_commands {
//  type = list(object({ command = list(string) }))
//  default = []
//}
//
//variable worker_name {
//  type = string
//  default = "worker"
//}

variable workers {
  type = object({
    image = string
    replicas = number
    expose = optional(list(object({
      port = number
      container_port = optional(number)
      host = optional(string)
      protocol = optional(string)
    })))
    name = optional(string)
    args = optional(list(string))
    env = optional(map(string))
    user = optional(string)
    pre = optional(list(object({
      args = optional(list(string))
      image = optional(string)
      user = optional(string)
    })))
    mounts = optional(list(object({
      src = string
      target = string
      type = optional(string)
      readonly = optional(bool)
    })))
  })
}

locals {
  workers = {
    image = var.workers.image
    name = var.workers.name == null ? "worker" : var.workers.name
    args = var.workers.args == null ? [] : var.workers.args
    env = var.workers.env == null ? {} : var.workers.env
    user = var.workers.user
    replicas = var.workers.replicas
    expose = var.workers.expose == null ? [] : [for e in var.workers.expose: jsondecode(templatefile("${path.module}/templates/expose.json.tpl", e))]
    mounts = var.workers.mounts == null ? [] : [for m in var.workers.mounts: jsondecode(templatefile("${path.module}/templates/mounts.json.tpl", m))]
    pre = var.workers.pre == null ? [] : [for init in var.workers.pre: {
      args = init.args == null ? [] : init.args
      image = init.image == null ? var.workers.image : init.image
      user = init.user
    }]
  }

  // Build worker arg file.
  arg_files_workers = {
    (local.workers.name) = join("\n", concat(
      [for arg_index, arg in local.workers.args: "ARG_MAIN_${arg_index}=${arg}"],
      flatten([for init_index, init in local.workers.pre: [
        for arg_index, arg in init.args: "ARG_INIT_${init_index + 1}_${arg_index}=${arg}"
      ]]),
      [""]
    ))
  }

  // Build worker env file.
  env_files_workers = {
    (local.workers.name) = join("\n", concat(
      [for k, v in local.workers.env: "${k}=${v}"],
      [""]
    ))
  }

  // Build worker unit file.
  unit_files_workers = {
    "${local.workers.name}@.service" = templatefile("${path.module}/templates/systemd-service.tpl", {
      type = "exec"
      requires = local.cloudsql_systemd_requires
      arg_file = keys(local.arg_files_workers)[0]
      exec_start_pre = concat(local.cloudsql_systemd_exec_start_pre, [
        for init_index, init in local.workers.pre:
          templatefile("${path.module}/templates/docker-run.tpl", {
            name = "${local.workers.name}-%i-init${init_index + 1}"
            env_file = keys(local.env_files_workers)[0]
            user = init.user
            labels = { part-of = "worker-init" }
            mounts = concat(local.cloudsql_mounts, local.workers.mounts)
            expose = []
            image = init.image
            args = [for index, cmd in init.args: "ARG_INIT_${init_index + 1}_${index}"]
          })
      ])
      exec_stop = templatefile("${path.module}/templates/docker-stop.tpl", { name = "${local.workers.name}-%i" })
      exec_start = templatefile("${path.module}/templates/docker-run.tpl", {
        name = "${local.workers.name}-%i"
        env_file = keys(local.env_files_workers)[0]
        user = local.workers.user
        labels = { part-of = "worker" }
        mounts = concat(local.cloudsql_mounts, local.workers.mounts)
        expose = local.workers.expose
        image = local.workers.image
        args = [for index, cmd in local.workers.args: "ARG_MAIN_${index}"]
      })
    })
  }
}