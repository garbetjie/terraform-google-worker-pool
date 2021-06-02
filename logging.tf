variable logging {
  type = object({
    driver = string
    options = optional(map(string))
  })

  default = {
    driver = "local"
  }
}

locals {
  logging = {
    driver = var.logging.driver
    options = var.logging.options == null ? lookup(local.logging_defaults, var.logging.driver, {}) : var.logging.options
  }

  logging_defaults = {
    json-file = {
      max-size = "50m"
      max-file = "10"
      compress = "true"
    }
    local = {
      max-size = "50m"
      max-file = "10"
      compress = "true"
    }
  }
}

output logging {
  value = {
    driver = local.logging.driver
    options = local.logging.options
  }
}