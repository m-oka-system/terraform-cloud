terraform {
  required_providers {
    tfe = {
      version = "~> 0.38.0"
    }
    github = {
      source  = "integrations/github"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
}

provider "azuread" {}

provider "github" {
  token = var.github_token
}

##################################
# Terraform Cloud
##################################
data "tfe_organization" "org" {
  name = var.tfc_organization_name
}

resource "tfe_workspace" "tutorial" {
  name         = var.tfc_workspace_name
  organization = data.tfe_organization.org.name
  auto_apply   = true
}

# Workspace variables
resource "tfe_variable" "azure_provider_auth" {
  key          = "TFC_AZURE_PROVIDER_AUTH"
  value        = true
  category     = "env"
  workspace_id = tfe_workspace.tutorial.id
}

resource "tfe_variable" "azure_client_id" {
  key          = "TFC_AZURE_RUN_CLIENT_ID"
  value        = azuread_application.tfc_application.application_id
  category     = "env"
  workspace_id = tfe_workspace.tutorial.id
  sensitive    = true
}

resource "tfe_variable" "azure_subscription_id" {
  key          = "ARM_SUBSCRIPTION_ID"
  value        = data.azurerm_subscription.current.subscription_id
  category     = "env"
  workspace_id = tfe_workspace.tutorial.id
  sensitive    = true
}

resource "tfe_variable" "azure_tenant_id" {
  key          = "ARM_TENANT_ID"
  value        = data.azurerm_subscription.current.tenant_id
  category     = "env"
  workspace_id = tfe_workspace.tutorial.id
  sensitive    = true
}

##################################
# Azure subscription and Azure AD
##################################
data "azurerm_subscription" "current" {}

locals {
  tfc_roles = [
    "Contributor",
    "Key Vault Administrator",
    "User Access Administrator"
  ]
}

resource "azuread_application" "tfc_application" {
  display_name = "terraform-cloud-dev"
}

resource "azuread_service_principal" "tfc_service_principal" {
  application_id = azuread_application.tfc_application.application_id
}

resource "azurerm_role_assignment" "tfc_role_assignment" {
  count                = length(local.tfc_roles)
  scope                = data.azurerm_subscription.current.id
  principal_id         = azuread_service_principal.tfc_service_principal.object_id
  role_definition_name = local.tfc_roles[count.index]
}

resource "azuread_application_federated_identity_credential" "tfc_federated_credential_plan" {
  application_object_id = azuread_application.tfc_application.object_id
  display_name          = "tfc-federated-credential-plan"
  audiences             = [var.tfc_azure_audience]
  issuer                = "https://${var.tfc_hostname}"
  subject               = "organization:${var.tfc_organization_name}:project:${var.tfc_project_name}:workspace:${var.tfc_workspace_name}:run_phase:plan"
}

resource "azuread_application_federated_identity_credential" "tfc_federated_credential_apply" {
  application_object_id = azuread_application.tfc_application.object_id
  display_name          = "tfc-federated-credential-apply"
  audiences             = [var.tfc_azure_audience]
  issuer                = "https://${var.tfc_hostname}"
  subject               = "organization:${var.tfc_organization_name}:project:${var.tfc_project_name}:workspace:${var.tfc_workspace_name}:run_phase:apply"
}

##################################
# GitHub
##################################
resource "github_repository" "terraform_cloud" {
  name       = var.github_repo_name
  visibility = "public"
}

resource "github_actions_secret" "tf_api_token" {
  repository      = github_repository.terraform_cloud.name
  secret_name     = "TF_API_TOKEN"
  encrypted_value = var.tfc_encrypted_token # gh secret set TF_API_TOKEN --no-store
}
