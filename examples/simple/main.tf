provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "default" {
  name     = "adfsimple-example-rg"
  location = "northeurope"
}

resource "azurerm_user_assigned_identity" "default" {
  name                = "adfsimple-uami"
  location            = azurerm_resource_group.default.location
  resource_group_name = azurerm_resource_group.default.name
}

resource "random_string" "default" {
  length    = 6
  min_lower = 6
}

resource "azurerm_storage_account" "default" {
  name                     = "adfsimple${random_string.default.result}st"
  location                 = azurerm_resource_group.default.location
  resource_group_name      = azurerm_resource_group.default.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
  #is_hns_enabled           = true
}

module "adf" {
  source              = "../../"
  resource_group_name = azurerm_resource_group.default.name
  data_factory = {
    name                   = "adfsimple"
    public_network_enabled = false

    identity = {
      type         = "SystemAssigned, UserAssigned"
      identity_ids = [azurerm_user_assigned_identity.default.id]
    }

    global_parameter = {
      environment = { value = "dev" }
    }
  }

  managed_private_endpoints = {
    "adfsimple${random_string.default.result}st" = {
      target_resource_id = azurerm_storage_account.default.id
      subresource_name   = "blob"
    }
  }
}
