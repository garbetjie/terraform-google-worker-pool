variable timers {
  type = list(
    object({
      schedule = string
      args = optional(list(string))
      image = optional(string)
      user = optional(string)
      env = optional(map(string))
//      pre = optional(list(object({
//        args = optional(list(string))
//        image = optional(string)
//        user = optional(string)
//      })))
      mounts = optional(list(object({
        src = string
        target = string
        type = optional(string)
        readonly = optional(bool)
      })))
    })
  )
  default = []
  description = "Scheduled timers to execute on instances."
}

locals {
  timers = [
    for index, timer in var.timers: {
      name = "timer-${format("%02d", index + 1)}"
      schedule = timer.schedule
      args = timer.args == null ? [] : timer.args
      user = timer.user
      image = timer.image == null ? local.workers.image : timer.image
      env = timer.env == null ? local.workers.env : timer.env
      mounts = timer.mounts == null ? local.workers.mounts : [for m in timer.mounts: jsondecode(templatefile("${path.module}/templates/mount.json.tpl", m))]
      pre = []
//      pre = timer.pre == null ? [] : [for init in timer.pre: {
//        args = init.args == null ? [] : init.args
//        image = coalesce(init.image, timer.image, local.workers.image)
//        user = init.user
//      }]
    }
  ]

  // Build up timer arg files.
  arg_files_timers = {
    for timer in local.timers:
      (timer.name) => join("\n", concat(
        [for arg_index, arg in timer.args: "ARG_MAIN_${arg_index}=${arg}"],
        flatten([for init_index, init in timer.pre: [
            for arg_index, arg in init.args: "ARG_INIT_${init_index + 1}_${arg_index}=${arg}"
        ]]),
        [""],
      ))
  }

  // Build up timer env files.
  env_files_timers = {
    for timer in local.timers:
      (timer.name) => join("\n", concat(
        [for k, v in timer.env: "${k}=${v}"],
        [""]
      ))
  }

  unit_files_timers = merge(
    {for timer in local.timers:
      "${timer.name}.timer" => templatefile("${path.module}/templates/systemd-timer.tpl", timer)
    },
    {for timer in local.timers:
      "${timer.name}.service" => templatefile("${path.module}/templates/systemd-service.tpl", {
        type = "exec"
        arg_file = timer.name
        requires = local.cloudsql_systemd_requires
        exec_start_pre = local.cloudsql_systemd_exec_start_pre
        exec_stop = null
        exec_start = join(" ", ["/bin/sh", "/etc/runtime/scripts/run-timer.sh", templatefile("${path.module}/templates/docker-run.tpl", {
          name = timer.name
          env_file = timer.name
          user = timer.user
          labels = { part-of = "timer" }
          mounts = concat(local.cloudsql_mounts, timer.mounts)
          expose = []
          image = timer.image
          args = [for index, arg in timer.args: "ARG_MAIN_${index}"]
        })])
      })
    }
  )

  script_files_timers = {
    "run-timer.sh" = file("${path.module}/files/script-run-timer.sh")
  }
}

output timers {
  value = [for timer in local.timers: {
    schedule = timer.schedule
    args = timer.args
    image = timer.image
    user = timer.user
    env = timer.env
//    pre = timer.pre
    mounts = timer.mounts
  }]
}