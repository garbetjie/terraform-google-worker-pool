variable name {
  type = string
  description = "Name of the worker group."
}

variable workers_per_instance {
  type = number
  description = "Number of workers to start up per instance."
}

variable location {
  type = string
  description = "Zone or region in which to run the workers."
}

variable image {
  type = string
  description = "Docker image to use to run the workers."
}

variable service_account_email {
  type = string
  default = null
  description = "Service account to assign to the worker instances."
}

variable machine_type {
  type = string
  default = "f1-micro"
  description = "Machine type to create the worker instances as."
}

variable worker_name {
  type = string
  default = "worker"
  description = "Prefix to apply to containers and systemd services generated for workers."
}

variable env {
  type = map(string)
  default = {}
  description = "Environment variables to inject into workers and timers."
}

variable labels {
  type = map(string)
  default = {}
  description = "Labels to apply to all instances in the group."
}

variable network {
  type = string
  default = "default"
  description = "Network in which to create worker instances."
}

variable instance_count {
  type = number
  default = 1
  description = "Number of instances to create."
}

variable args {
  type = list(string)
  default = []
  description = "Arguments to pass to workers. Not currently escaped."
}

variable cloudsql_connections {
  type = set(string)
  default = []
  description = "List of CloudSQL connections to establish before starting workers."
}

variable cloudsql_path {
  type = string
  default = "/cloudsql"
  description = "The path into the workers and timers will have CloudSQL connections mounted."
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
    error_message = "Disk type must be one of [pd-ssd, local-ssd, pd-balanced, pd-standard]"
  }
}

variable preemptible {
  type = bool
  default = true
  description = "Whether or not to create preemptible instances."
}

variable log_driver {
  type = string
  default = "local"
  description = "Default log driver to be used in the Docker daemon."
}

variable log_opts {
  type = map(string)
  default = null
  description = "Options for configured log driver. Sensible defaults are used."
}

variable timers {
  type = list(object({ name = string, schedule = string, args = list(string) }))
  default = []
  description = "Scheduled timers to execute on the worker (also known as crons)."
}
