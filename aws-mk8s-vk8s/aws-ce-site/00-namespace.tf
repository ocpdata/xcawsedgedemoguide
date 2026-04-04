locals {
  module2_namespace_name = trimspace(var.environment)
}

resource "volterra_namespace" "buytime" {
  count = var.create_module2_foundations && var.create_namespace ? 1 : 0

  name = local.module2_namespace_name
}

data "volterra_namespace" "buytime_existing" {
  count = var.create_module2_foundations && !var.create_namespace ? 1 : 0

  name = local.module2_namespace_name
}

locals {
  module2_namespace_ref = var.create_namespace ? volterra_namespace.buytime[0].name : data.volterra_namespace.buytime_existing[0].name
}