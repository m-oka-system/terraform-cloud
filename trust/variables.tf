# Azure
variable "tfc_azure_audience" {
  type        = string
  default     = "api://AzureADTokenExchange"
  description = "The audience value to use in run identity tokens"
}

variable "tfc_hostname" {
  type        = string
  default     = "app.terraform.io"
  description = "The hostname of the TFC or TFE instance you'd like to use with Azure"
}

variable "tfc_organization_name" {
  type        = string
  description = "The name of your Terraform Cloud organization"
}

variable "tfc_project_name" {
  type        = string
  default     = "Default Project"
  description = "The project under which a workspace will be created"
}

variable "tfc_workspace_name" {
  type        = string
  default     = "my-azure-workspace"
  description = "The name of the workspace that you'd like to create and connect to Azure"
}

# GitHub
variable "oauth_connection_name" {
  type    = string
  default = "HashiCat Workshop"
}

variable "github_organization" {
  type = string
}

variable "github_repo_name" {
  type = string
}

variable "github_token" {
  type = string
}

variable "tfc_encrypted_token" {
  type = string
}
