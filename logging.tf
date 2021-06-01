variable logging {
  type = object({
    driver = optional(string)
    options = optional(map(string))
  })

  default = {
    driver = "local"
  }
}

locals {
  logging_driver = var.logging.driver
  logging_options = var.logging.options != null ? var.logging.options : lookup(local.logging_defaults, var.logging.driver, {})

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
    driver = local.logging_driver
    options = local.logging_options
  }
}