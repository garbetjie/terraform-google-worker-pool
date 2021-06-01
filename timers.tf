variable timers {
  type = list(
    object({
      schedule = string
      command = list(string)
      name = optional(string)
      image = optional(string)
      user = optional(string)
      env = optional(map(string))
      mounts = optional(list(object({
        name = string
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
  timers = [for index, timer in var.timers: {
    schedule = timer.schedule
    command = timer.command
    env = timer.env == null ? local.worker.env : timer.env
    name = timer.name == null ? "timer-${format("%02d", index + 1)}" : "timer-${timer.name}"
    image = timer.image != null ? timer.image : local.worker.image
    user = timer.user
    mounts = timer.mounts == null ? [] : [
      for mount in timer.mounts: templatefile("${path.module}/parts/mount.tpl", { mount = mount })
    ]
  }]

  // Build up timer arg files.
  timer_arg_file_contents = {
    for timer in local.timers:
      timer.name => join("\n", concat(
        [for index in range(length(timer.command)): format("ARG%d=%s", index, timer.command[index])],
        [""]
      ))
  }

  // Build up timer env files.
  timer_env_file_contents = {
    for timer in local.timers:
      timer.name => join("\n", concat(
        [for k, v in timer.env: "${k}=${v}"],
        [""]
      ))
  }

  timer_unit_file_contents = merge(
    {for timer in local.timers:
      "${timer.name}.timer" => templatefile("${path.module}/templates/systemd-timer.tpl", {
        name = timer.name
        schedule = timer.schedule
      })
    },
    {for timer in local.timers:
      "${timer.name}.service" => templatefile("${path.module}/templates/systemd-service.tpl", {
        type = "exec"
        cloudsql_required = local.requires_cloudsql
        cloudsql_wait = local.wait_for_cloudsql
        arg_file = timer.name
        pre_start = []
        stop = ""
        start = templatefile("${path.module}/templates/docker-run.tpl", {
          name = timer.name
          env_file = timer.name
          user = timer.user
          labels = { part-of = "timer" }
          mounts = concat(local.cloudsql_mounts, timer.mounts)
          expose = []
          image = timer.image
          command = timer.command
        })
      })
    }
  )
}