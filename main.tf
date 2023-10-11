locals {
  tags = merge(var.tags, { ManagedByTerraform = "True" })
}

resource "azurerm_data_factory" "default" {
  name                             = "${var.data_factory.name}-adf"
  resource_group_name              = var.resource_group_name
  location                         = var.location
  managed_virtual_network_enabled  = var.data_factory.managed_virtual_network_enabled
  public_network_enabled           = var.data_factory.public_network_enabled
  customer_managed_key_id          = var.data_factory.customer_managed_key_id
  customer_managed_key_identity_id = var.data_factory.customer_managed_key_identity_id
  purview_id                       = var.data_factory.purview_id
  tags                             = local.tags

  dynamic "global_parameter" {
    for_each = var.data_factory.global_parameter == null ? {} : { for key, value in var.data_factory.global_parameter : key => value }
    content {
      name  = global_parameter.key
      type  = global_parameter.value.type
      value = global_parameter.value.value
    }
  }

  dynamic "identity" {
    for_each = var.data_factory.identity == null ? [] : [var.data_factory.identity]
    content {
      type         = identity.value.type
      identity_ids = identity.value.identity_ids
    }
  }

  dynamic "github_configuration" {
    for_each = var.data_factory.github_configuration == null ? [] : [var.data_factory.github_configuration]
    content {
      account_name       = github_configuration.value.account_name
      branch_name        = github_configuration.value.branch_name
      git_url            = github_configuration.value.git_url
      repository_name    = github_configuration.value.repository_name
      root_folder        = github_configuration.value.root_folder
      publishing_enabled = github_configuration.value.publishing_enabled
    }
  }

  dynamic "vsts_configuration" {
    for_each = var.data_factory.vsts_configuration == null ? [] : [var.data_factory.vsts_configuration]
    content {
      account_name       = vsts_configuration.value.account_name
      branch_name        = vsts_configuration.value.branch_name
      project_name       = vsts_configuration.value.project_name
      repository_name    = vsts_configuration.value.repository_name
      root_folder        = vsts_configuration.value.root_folder
      tenant_id          = vsts_configuration.value.tenant_id
      publishing_enabled = vsts_configuration.value.publishing_enabled
    }
  }
}

resource "azurerm_data_factory_managed_private_endpoint" "default" {
  for_each           = var.managed_private_endpoints == null ? {} : { for key, value in var.managed_private_endpoints : key => value }
  name               = each.key
  data_factory_id    = azurerm_data_factory.default.id
  target_resource_id = each.value.target_resource_id
  subresource_name   = each.value.subresource_name
}
