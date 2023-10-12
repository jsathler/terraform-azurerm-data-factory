locals {
  prefix = basename(path.cwd)
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "default" {
  name     = "${local.prefix}-example-rg"
  location = "northeurope"
}

resource "azurerm_user_assigned_identity" "default" {
  name                = "${local.prefix}-uami"
  location            = azurerm_resource_group.default.location
  resource_group_name = azurerm_resource_group.default.name
}

resource "random_string" "default" {
  length    = 6
  min_lower = 6
}

module "adf" {
  source              = "../../"
  resource_group_name = azurerm_resource_group.default.name
  data_factory = {
    name             = "${local.prefix}${random_string.default.result}"
    identity         = {}
    global_parameter = { environment = { value = "dev" } }
  }
}

output "adf" {
  value = module.adf
}
