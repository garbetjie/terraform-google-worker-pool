variable name {
  type = string
  description = "Name of the pool."
}

variable location {
  type = string
  description = "Zone or region in which to create the pool."
}

variable disk_size {
  type = number
  default = 25
  description = "Disk size (in GB) to create instances with."
}

variable disk_type {
  type = string
  default = "pd-balanced"
  description = "Disk type to create instances with."

  validation {
    condition = contains(["pd-ssd", "local-ssd", "pd-balanced", "pd-standard"], var.disk_type)
    error_message = "Disk type must be one of [pd-ssd, local-ssd, pd-balanced, pd-standard]."
  }
}

variable instance_count {
  type = number
  default = 1
  description = "Number of instances to create in the pool."
}

variable labels {
  type = map(string)
  default = {}
  description = "Labels to apply to all instances in the pool."
}

variable machine_type {
  type = string
  default = "f1-micro"
  description = "Machine type to create instances in the pool with."
}

variable metadata {
  type = map(string)
  default = {}
  description = "Additional metadata to add to instances. Keys used by this module will be overwritten."
}

variable network {
  type = string
  default = "default"
  description = "Network name or link in which to create the pool."
}

variable preemptible {
  type = bool
  default = false
  description = "Whether or not to create preemptible instances."
}

variable restart_interval {
  type = number
  default = 5
  description = "Number of seconds to wait before restarting a failed worker."
}

variable restart_policy {
  type = string
  default = "always"
  description = "Restart policy to apply to failed workers."

  validation {
    condition = contains(["no", "on-success", "on-failure", "on-abnormal", "on-watchdog", "on-abort", "always"], var.restart_policy)
    error_message = "Restart policy must be one of [always, no, on-success, on-failure, on-abnormal, on-watchdog, on-abort]."
  }
}

variable runcmd {
  type = list(string)
  default = []
  description = "Additional commands to run on instance startup. These commands are run after Docker is configured & restarted, and immediately before any workers & CloudSQL connections are started."
}

variable service_account_email {
  type = string
  default = null
  description = "Service account to assign to the pool."
}

variable tags {
  type = list(string)
  default = []
  description = "Network tags to apply to instances in the pool."
}

variable timezone {
  type = string
  default = "Etc/UTC"
  description = "Timezone to use on instances. See the \"TZ database name\" column on https://en.wikipedia.org/wiki/List_of_tz_database_time_zones for an indication as to available timezone names."
}

variable wait_for_instances {
  type = bool
  default = false
  description = "Wait for instances to stabilise starting after updating the pool's instance group."
}
