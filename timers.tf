variable timers {
  type = list(
    object({
      schedule = string
      command = optional(list(string))
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
  // Build up correct defaults.
  timer_names = [for i, t in var.timers: (t.name == null || t.name == "" ? "timer-${format("%02d", i + 1)}" : t.name)]
  timer_commands = [for t in var.timers: (t.command == null ? [] : t.command)]
  timer_schedules = [for t in var.timers: t.schedule]
  timer_images = [for t in var.timers: (t.image == null ? local.worker_image : t.image)]
  timer_users = [for t in var.timers: t.user]
  timer_envs = [for t in var.timers: (t.env == null ? local.worker_env : t.env)]
  timer_mounts = [for t in var.timers: (
    t.mounts == null ? local.worker_mounts : [
      for m in t.mounts: templatefile("${path.module}/parts/mount.tpl", { mount = m })
    ]
  )]

  // Build up timer arg files.
  timer_arg_files = {
    for name_index, name in local.timer_names:
      name => join("\n", concat(
        [for cmd_index, cmd in local.timer_commands[name_index]: format("ARG%d=%s", cmd_index, cmd)],
        [""]
      ))
  }

  // Build up timer env files.
  timer_env_files = {
    for index, name in local.timer_names:
      name => join("\n", concat(
        [for k, v in local.timer_envs[index]: "${k}=${v}"],
        [""]
      ))
  }

  timer_unit_files = merge(
    {for index, name in local.timer_names:
      "${name}.timer" => templatefile("${path.module}/templates/systemd-timer.tpl", {
        name = name
        schedule = local.timer_schedules[index]
      })
    },
    {for index, name in local.timer_names:
      "${name}.service" => templatefile("${path.module}/templates/systemd-service.tpl", {
        type = "exec"
        arg_file = name
        requires = local.cloudsql_provided_requires
        exec_start_pre = local.cloudsql_provided_exec_start_pre
        exec_stop = templatefile("${path.module}/templates/docker-stop.tpl", { name = name })
        exec_start = templatefile("${path.module}/templates/docker-run.tpl", {
          name = name
          env_file = name
          user = local.timer_users[index]
          labels = { part-of = "timer" }
          mounts = concat(local.cloudsql_provided_mounts, local.timer_mounts[index])
          expose = []
          image = local.timer_images[index]
          command = local.timer_commands[index]
        })
      })
    }
  )
}