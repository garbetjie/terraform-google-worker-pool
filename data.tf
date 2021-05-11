data google_compute_zones regional_zones {
  count = local.is_regional_manager ? 1 : 0
  region = var.location
}