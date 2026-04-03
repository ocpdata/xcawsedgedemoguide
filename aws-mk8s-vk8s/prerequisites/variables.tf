variable "project_prefix" {
  description = "Prefix used for AWS and XC resource names."
  type        = string
}

variable "xc_namespace" {
  description = "XC namespace used for module 1 resources."
  type        = string
}

variable "create_xc_namespace" {
  description = "Whether prerequisites should create the XC namespace when it does not already exist."
  type        = bool
  default     = true
}

variable "xc_api_url" {
  description = "F5 Distributed Cloud API URL."
  type        = string
}

variable "xc_api_p12_file" {
  description = "Path to the XC API P12 credential file."
  type        = string
}

variable "aws_region" {
  description = "AWS region where the App Stack site will be created."
  type        = string
}

variable "aws_access_key" {
  description = "AWS access key used by Terraform."
  type        = string
  sensitive   = true
}

variable "aws_secret_key" {
  description = "AWS secret key used by Terraform."
  type        = string
  sensitive   = true
}

variable "vpc_cidr" {
  description = "Primary VPC CIDR for the App Stack site."
  type        = string

  validation {
    condition     = length(trimspace(var.vpc_cidr)) > 0 && can(cidrnetmask(var.vpc_cidr))
    error_message = "vpc_cidr must be a non-empty valid CIDR block, for example 10.0.0.0/16."
  }
}

variable "existing_mk8s_cluster_name" {
  description = "Optional existing XC managed k8s cluster name to reuse instead of creating a new one."
  type        = string
  default     = ""
}

variable "windows_admin_password" {
  description = "Optional password to assign to the Windows Administrator account on the kiosk VM."
  type        = string
  sensitive   = true
  default     = ""

  validation {
    condition = var.windows_admin_password == "" || (
      length(var.windows_admin_password) >= 8 &&
      can(regex("[A-Z]", var.windows_admin_password)) &&
      can(regex("[a-z]", var.windows_admin_password)) &&
      can(regex("[0-9]", var.windows_admin_password)) &&
      can(regex("[^A-Za-z0-9]", var.windows_admin_password))
    )
    error_message = "windows_admin_password must be empty or be at least 8 characters long and include uppercase, lowercase, numeric, and special characters. Example: Password123!."
  }
}
