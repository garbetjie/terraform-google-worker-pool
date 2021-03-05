variable name {
  type = string
}

variable workers_per_instance {
  type = number
}

variable location {
  type = string
}

variable image {
  type = string
}

variable service_account_email {
  type = string
  default = null
}

variable machine_type {
  type = string
  default = "f1-micro"
}

variable env {
  type = map(string)
  default = {}
}

variable labels {
  type = map(string)
  default = {}
}

variable network {
  type = string
  default = "default"
}

variable instance_count {
  type = number
  default = 1
}

variable args {
  type = list(string)
  default = []
}

variable cloudsql_connections {
  type = set(string)
  default = []
}

variable cloudsql_path {
  type = string
  default = "/cloudsql"
}

variable disk_size {
  type = number
  default = 25
}

variable disk_type {
  type = string
  default = "pd-standard"
}

variable preemptible {
  type = bool
  default = true
}
