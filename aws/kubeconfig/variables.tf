variable "project_prefix" {
  description = "Prefix used to name the temporary kubeconfig credential."
  type        = string
}

variable "site_name" {
  description = "XC site name used to request a site global kubeconfig."
  type        = string
}

variable "credential_name" {
  description = "Optional explicit name for the temporary service credential."
  type        = string
  default     = ""
}

variable "xc_api_url" {
  description = "F5 Distributed Cloud API URL."
  type        = string
}

variable "xc_api_p12_file" {
  description = "Path to the XC API P12 credential file."
  type        = string
}