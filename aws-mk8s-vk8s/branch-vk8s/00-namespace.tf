locals {
  branch_fleet_namespace = trimspace(var.environment)
}

resource "volterra_namespace" "branch_fleet" {
  count = var.create_namespace ? 1 : 0

  name = local.branch_fleet_namespace
}

data "volterra_namespace" "branch_fleet_existing" {
  count = var.create_namespace ? 0 : 1

  name = local.branch_fleet_namespace
}

locals {
  branch_fleet_namespace_ref = var.create_namespace ? volterra_namespace.branch_fleet[0].name : data.volterra_namespace.branch_fleet_existing[0].name
}