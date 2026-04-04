resource "volterra_virtual_site" "buytime_re" {
  count = var.create_module2_foundations ? 1 : 0

  name      = "buytime-re-sites"
  namespace = volterra_namespace.buytime[0].name

  site_selector {
    expressions = ["ves.io/region in (ves-io-seattle, ves-io-singapore, ves-io-stockholm)"]
  }

  site_type = "REGIONAL_EDGE"

  depends_on = [
    volterra_namespace.buytime,
  ]
}

resource "volterra_virtual_site" "buytime_ce" {
  count = var.create_module2_foundations ? 1 : 0

  name      = "buytime-ce-sites"
  namespace = volterra_namespace.buytime[0].name

  site_selector {
    expressions = ["location in (buytime-ce-site)"]
  }

  site_type = "CUSTOMER_EDGE"

  depends_on = [
    volterra_namespace.buytime,
  ]
}

resource "volterra_virtual_k8s" "buytime" {
  count = var.create_module2_foundations ? 1 : 0

  name      = "buytime-online-vk8s"
  namespace = volterra_namespace.buytime[0].name
  vsite_refs {
    name = volterra_virtual_site.buytime_ce[0].name
  }
    
  vsite_refs {
    name = volterra_virtual_site.buytime_re[0].name
  }
}

resource "volterra_api_credential" "buytime" {
  count = var.create_module2_foundations ? 1 : 0

  created_at = timestamp()
  name                  = "buytime-online-kubeconfig"
  api_credential_type   = "KUBE_CONFIG"
  virtual_k8s_namespace = volterra_namespace.buytime[0].name
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