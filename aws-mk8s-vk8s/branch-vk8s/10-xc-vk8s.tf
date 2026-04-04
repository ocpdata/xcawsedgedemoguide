resource "volterra_virtual_site" "branch_fleet" {
  count = var.create_virtual_site ? 1 : 0

  name      = var.virtual_site_name
  namespace = local.branch_fleet_namespace_ref

  site_selector {
    expressions = [var.branch_site_selector_expression]
  }

  site_type = "CUSTOMER_EDGE"
}

resource "volterra_virtual_k8s" "branch_fleet" {
  count = var.create_virtual_k8s ? 1 : 0

  name      = var.virtual_k8s_name
  namespace = local.branch_fleet_namespace_ref

  vsite_refs {
    name = var.virtual_site_name
  }

  depends_on = [
    volterra_virtual_site.branch_fleet,
  ]
}

resource "volterra_api_credential" "branch_fleet" {
  count = var.create_api_credential ? 1 : 0

  created_at              = timestamp()
  name                    = var.api_credential_name
  api_credential_type     = "KUBE_CONFIG"
  virtual_k8s_namespace   = local.branch_fleet_namespace_ref
  virtual_k8s_name        = var.virtual_k8s_name

  depends_on = [
    volterra_virtual_k8s.branch_fleet,
  ]
}

resource "local_file" "kubeconfig" {
  count = var.create_api_credential ? 1 : 0

  content_base64 = volterra_api_credential.branch_fleet[0].data
  filename       = var.kubeconfig_path
}

output "namespace" {
  value       = local.branch_fleet_namespace_ref
  description = "XC namespace used by the branch fleet virtual k8s."
}

output "virtual_site_name" {
  value       = var.virtual_site_name
  description = "Name of the branch fleet virtual site."
}

output "virtual_k8s_name" {
  value       = var.virtual_k8s_name
  description = "Name of the branch fleet virtual k8s."
}

output "kubeconfig_path" {
  value       = var.create_api_credential ? var.kubeconfig_path : ""
  description = "Path to the generated branch fleet vK8s kubeconfig."
}