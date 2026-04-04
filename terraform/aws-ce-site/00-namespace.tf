resource "volterra_namespace" "buytime" {
  count = var.create_module2_foundations ? 1 : 0

  name = "buytime-online"
}