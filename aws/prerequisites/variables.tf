variable "project_prefix" {
  description = "Prefix used for AWS and XC resource names."
  type        = string
}

variable "xc_namespace" {
  description = "XC namespace used for module 1 resources."
  type        = string
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
}