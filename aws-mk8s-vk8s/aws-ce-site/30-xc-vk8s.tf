locals {
  buytime_re_virtual_site_name = "buytime-re-sites"
  buytime_ce_virtual_site_name = "buytime-ce-sites"
}

resource "volterra_virtual_site" "buytime_re" {
  count = var.create_module2_foundations && var.create_re_virtual_site ? 1 : 0

  name      = local.buytime_re_virtual_site_name
  namespace = local.module2_namespace_ref

  site_selector {
    expressions = ["ves.io/region in (ves-io-seattle, ves-io-singapore, ves-io-stockholm)"]
  }

  site_type = "REGIONAL_EDGE"

}

resource "volterra_virtual_site" "buytime_ce" {
  count = var.create_module2_foundations && var.create_ce_virtual_site ? 1 : 0

  name      = local.buytime_ce_virtual_site_name
  namespace = local.module2_namespace_ref

  site_selector {
    expressions = ["location in (buytime-ce-site)"]
  }

  site_type = "CUSTOMER_EDGE"

}

resource "volterra_virtual_k8s" "buytime" {
  count = var.create_module2_foundations ? 1 : 0

  name      = "buytime-online-vk8s"
  namespace = local.module2_namespace_ref
  vsite_refs {
    name = local.buytime_ce_virtual_site_name
  }
    
  vsite_refs {
    name = local.buytime_re_virtual_site_name
  }
}

resource "volterra_api_credential" "buytime" {
  count = var.create_module2_foundations ? 1 : 0

  created_at = timestamp()
  name                  = "buytime-online-kubeconfig"
  api_credential_type   = "KUBE_CONFIG"
  virtual_k8s_namespace = local.module2_namespace_ref
  virtual_k8s_name      = volterra_virtual_k8s.buytime[0].name
}

resource "local_file" "kubeconfig" {
  count          = var.create_module2_foundations ? 1 : 0
  content_base64 = volterra_api_credential.buytime[0].data
  filename       = "${var.kubeconfig_path}"
}

output "kubecofnig_path" {
 value       = var.create_module2_foundations ? var.kubeconfig_path : ""
 sensitive   = false
 description = "Kubeconfig path"
}

output "kubeconfig_path" {
 value       = var.create_module2_foundations ? var.kubeconfig_path : ""
 sensitive   = false
 description = "Kubeconfig path"
}