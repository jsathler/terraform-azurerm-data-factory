locals {
  shir_hosts           = ["shir01", "shir02"]
  azs                  = [1, 2, 3]
  prefix               = basename(path.cwd)
  storage_account_name = lower(replace("${local.prefix}${random_string.default.result}st", "/[^A-Za-z0-9]/", ""))
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "default" {
  name     = "${local.prefix}-example-rg"
  location = "northeurope"
}

resource "azurerm_user_assigned_identity" "default" {
  name                = "${local.prefix}-example-uami"
  location            = azurerm_resource_group.default.location
  resource_group_name = azurerm_resource_group.default.name
}

resource "random_string" "default" {
  length    = 6
  min_lower = 6
}

resource "random_password" "default" {
  length = 16
}

resource "azurerm_virtual_network" "default" {
  name                = "${local.prefix}-example-vnet"
  location            = azurerm_resource_group.default.location
  resource_group_name = azurerm_resource_group.default.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "default" {
  name                 = "default-snet"
  virtual_network_name = azurerm_virtual_network.default.name
  resource_group_name  = azurerm_resource_group.default.name
  address_prefixes     = ["10.0.0.0/24"]
}

resource "azurerm_storage_account" "default" {
  name                     = local.storage_account_name
  location                 = azurerm_resource_group.default.location
  resource_group_name      = azurerm_resource_group.default.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
  is_hns_enabled           = true
}

# module "shirs" {
#   for_each             = toset(local.shir_hosts)
#   source               = "jsathler/virtualmachine/azurerm"
#   name                 = each.key
#   location             = azurerm_resource_group.default.location
#   resource_group_name  = azurerm_resource_group.default.name
#   availability_zone    = element(local.azs, index(local.shir_hosts, each.key) % length(local.azs))
#   local_admin_name     = "localadmin"
#   local_admin_password = random_password.default.result
#   subnet_id            = [azurerm_subnet.default.id]
#   os_type              = "windows"
#   image_publisher      = "MicrosoftWindowsServer"
#   image_offer          = "WindowsServer"
#   image_sku            = "2022-datacenter-azure-edition"
# }

module "adf" {
  source              = "../../"
  resource_group_name = azurerm_resource_group.default.name
  data_factory = {
    name = "${local.prefix}${random_string.default.result}"

    identity = {
      type         = "SystemAssigned, UserAssigned"
      identity_ids = [azurerm_user_assigned_identity.default.id]
    }

    global_parameter = {
      environment = { value = "dev" }
    }
  }

  # managed_private_endpoints = {
  #   local.storage_account_name = {
  #     target_resource_id = azurerm_storage_account.default.id
  #     subresource_name   = "blob"
  #   }
  # }

  upload_script = {
    storage_account_id = azurerm_storage_account.default.id
  }

  irs = {
    ir1 = {}
    # ir2 = {
    #   type  = "Self-hosted"
    #   nodes = { for vm in module.shirs : vm.name => vm.id }
    # }
    #ir3 = { type = "Self-hosted", rbac_resource_id = ["/subscriptions/<subscription>/resourcegroups/<resource-group>/providers/Microsoft.DataFactory/factories/<shared-data-factory>/integrationruntimes/<shared-ir>"] }
  }
}

output "adf" {
  value = module.adf
}
