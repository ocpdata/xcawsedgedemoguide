variable "environment" {
  type        = string
  default     = "buytime-branches"
  description = "XC namespace used for the branch fleet vK8s objects."
}

variable "create_namespace" {
  type        = bool
  default     = true
  description = "Whether Terraform should create the branch fleet namespace or reuse an existing one."
}

variable "create_virtual_site" {
  type        = bool
  default     = true
  description = "Whether Terraform should create the branch fleet virtual site or reuse an existing one."
}

variable "create_virtual_k8s" {
  type        = bool
  default     = true
  description = "Whether Terraform should create the branch fleet virtual k8s or reuse an existing one."
}

variable "create_api_credential" {
  type        = bool
  default     = true
  description = "Whether Terraform should create an API credential and write a kubeconfig for the branch fleet vK8s."
}

variable "virtual_site_name" {
  type        = string
  default     = "buytime-branch-sites"
  description = "Name of the Customer Edge virtual site that groups branch App Stack sites."
}

variable "virtual_k8s_name" {
  type        = string
  default     = "buytime-branches-vk8s"
  description = "Name of the branch fleet virtual k8s object."
}

variable "api_credential_name" {
  type        = string
  default     = "buytime-branches-kubeconfig"
  description = "Name of the API credential used to generate the branch fleet vK8s kubeconfig."
}

variable "branch_site_selector_expression" {
  type        = string
  default     = "site_group in (buytime-branches)"
  description = "XC site selector expression used by the branch fleet virtual site."
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
  type        = string
  default     = "../branch-vk8s-kubeconfig.yaml"
  description = "Path where the generated branch fleet vK8s kubeconfig will be written."
}