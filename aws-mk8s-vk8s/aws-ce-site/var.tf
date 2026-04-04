variable "environment" {
  type        = string
  default     = "aws-ce-site"
  description = "Environment Name"
}

variable "site_name" {
  type        = string
  default     = ""
  description = "Optional explicit CE site name. When empty, environment is used."
}

variable "cloud_credential_name" {
  type        = string
  default     = ""
  description = "Optional existing XC cloud credential name. When empty, the CE site name is used."
}

variable "create_cloud_credential" {
  type        = bool
  default     = true
  description = "Whether Terraform should create the XC cloud credential or reuse an existing one."
}

variable "manage_site_infrastructure" {
  type        = bool
  default     = true
  description = "Whether Terraform should manage the CE AWS VPC, subnets, site object, and related site resources."
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

variable "vpc_cidr" {
  type        = string
  default     = "172.24.0.0/16"
  description = "Primary VPC CIDR for the CE site."

  validation {
    condition     = length(trimspace(var.vpc_cidr)) > 0 && can(cidrnetmask(var.vpc_cidr))
    error_message = "vpc_cidr must be a non-empty valid CIDR block, for example 172.24.0.0/16."
  }
}

variable "create_module2_foundations" {
  type        = bool
  default     = true
  description = "Whether to create the online namespace, virtual sites, vk8s, and kubeconfig used by Module 2."
}

variable "create_namespace" {
  type        = bool
  default     = true
  description = "Whether Terraform should create the Module 2 namespace or reuse an existing one."
}

variable "aws_region" {
  type    = string
  default = "us-east-2"
}

variable "aws_access_key" {
  type    = string
  default = "your_aws_access_key"
}

variable "aws_secret_key" {
  type    = string
  default = "your_aws_secret_key"
}