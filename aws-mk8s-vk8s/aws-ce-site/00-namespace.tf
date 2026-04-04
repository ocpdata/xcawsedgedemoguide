locals {
  module2_namespace_name = trimspace(var.environment)
}

resource "volterra_namespace" "buytime" {
  count = var.create_module2_foundations && var.create_namespace ? 1 : 0

  name = local.module2_namespace_name
}