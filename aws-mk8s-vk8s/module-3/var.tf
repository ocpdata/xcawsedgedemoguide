variable "environment" {
  type        = string
  default     = "buytime-online"
  description = "Environment Name"
}

variable "xc_api_url" {
  type    = string
  default = "https://your_tenant_name.console.ves.volterra.io/api"
}

variable "xc_api_p12_file" {
  type    = string
  default = "../api-creds.p12"
}

variable "kubeconfig_path" {
  type    = string
  default = "../kubeconfig_vk8s.yaml"
}

variable "user_domain" {
  type    = string
  default = "your_domain_name.example.com"
}

variable "create_origin_pool" {
  type        = bool
  default     = true
  description = "Whether Terraform should create the Module 3 origin pool or reuse an existing one."
}

variable "create_http_loadbalancer" {
  type        = bool
  default     = true
  description = "Whether Terraform should create the Module 3 HTTP load balancer or reuse an existing one."
}