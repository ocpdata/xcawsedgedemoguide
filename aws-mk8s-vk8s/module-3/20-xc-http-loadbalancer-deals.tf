locals {
  module3_http_loadbalancer_name = "${var.environment}-deals-server"
  module3_origin_pool_name       = "${var.environment}-deals-pool"
}

resource "volterra_http_loadbalancer" "deals" {
  count     = var.create_http_loadbalancer ? 1 : 0
  name      = local.module3_http_loadbalancer_name
  namespace = var.environment

  domains = ["deals.${var.user_domain}"]

  http {
    dns_volterra_managed = false
    port                 = "80"
  }

  default_route_pools {
    pool {
      name      = local.module3_origin_pool_name
      namespace = var.environment
    }
    priority = 1
    weight   = 1
  }

  advertise_on_public_default_vip  = true

  disable_api_definition           = true
  disable_api_discovery            = true
  no_challenge                     = true
  source_ip_stickiness             = true
  disable_malicious_user_detection = true
  disable_rate_limit               = true
  service_policies_from_namespace  = true
  disable_trust_client_ip_headers  = true
  user_id_client_ip                = true
  disable_waf                      = true

  depends_on = [
    volterra_origin_pool.deals,
  ]
}

resource "volterra_origin_pool" "deals" {
  count     = var.create_origin_pool ? 1 : 0
  name      = local.module3_origin_pool_name
  namespace = var.environment

  origin_servers {
    k8s_service {
      service_name = "deals-server-service.${var.environment}"
      site_locator {
        virtual_site {
          name      = "buytime-re-sites"
          namespace = var.environment
        }
      }
      vk8s_networks = true
    }
  }

  no_tls                 = true
  port                   = 8080
  endpoint_selection     = "LOCAL_PREFERRED"
  loadbalancer_algorithm = "LB_OVERRIDE"
}