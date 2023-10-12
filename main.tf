locals {
  tags = merge(var.tags, { ManagedByTerraform = "True" })
}

###########
# Data Factory
###########

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

###########
# Managed private endpoints
###########

resource "azurerm_data_factory_managed_private_endpoint" "default" {
  for_each           = var.managed_private_endpoints == null ? {} : { for key, value in var.managed_private_endpoints : key => value }
  name               = each.key
  data_factory_id    = azurerm_data_factory.default.id
  target_resource_id = each.value.target_resource_id
  subresource_name   = each.value.subresource_name
}

###########
# Integration Runtime
###########

resource "azurerm_data_factory_integration_runtime_azure" "default" {
  for_each                = { for key, value in var.irs : key => value if value.type == "Azure" }
  name                    = "${each.key}-adfira"
  description             = each.value.description
  data_factory_id         = azurerm_data_factory.default.id
  location                = each.value.location
  compute_type            = each.value.compute_type
  core_count              = each.value.core_count
  time_to_live_min        = each.value.time_to_live_min
  cleanup_enabled         = each.value.cleanup_enabled
  virtual_network_enabled = each.value.virtual_network_enabled
}

# resource "azurerm_data_factory_integration_runtime_azure_ssis" "default" {
#   for_each        = { for key, value in var.irs : key => value if value.type == "SSIS" }
#   name            = "${each.key}-adfira"
#   description     = each.value.description
#   data_factory_id = azurerm_data_factory.default.id
#   location        = each.value.location

#   node_size = "Standard_D8_v3"
# number_of_nodes - (Optional) Number of nodes for the Azure-SSIS Integration Runtime. Max is 10. Defaults to 1.
# max_parallel_executions_per_node - (Optional) Defines the maximum parallel executions per node. Defaults to 1. Max is 16.
# edition - (Optional) The Azure-SSIS Integration Runtime edition. Valid values are Standard and Enterprise. Defaults to Standard.
# license_type - (Optional) The type of the license that is used. Valid values are LicenseIncluded and BasePrice. Defaults to LicenseIncluded.
# package_store - (Optional) One or more package_store block as defined below.
# proxy - (Optional) A proxy block as defined below.  

# A catalog_info block supports the following:
# server_endpoint - (Required) The endpoint of an Azure SQL Server that will be used to host the SSIS catalog.
# administrator_login - (Optional) Administrator login name for the SQL Server.
# administrator_password - (Optional) Administrator login password for the SQL Server.
# pricing_tier - (Optional) Pricing tier for the database that will be created for the SSIS catalog. Valid values are: Basic, S0, S1, S2, S3, S4, S6, S7, S9, S12, P1, P2, P4, P6, P11, P15, GP_S_Gen5_1, GP_S_Gen5_2, GP_S_Gen5_4, GP_S_Gen5_6, GP_S_Gen5_8, GP_S_Gen5_10, GP_S_Gen5_12, GP_S_Gen5_14, GP_S_Gen5_16, GP_S_Gen5_18, GP_S_Gen5_20, GP_S_Gen5_24, GP_S_Gen5_32, GP_S_Gen5_40, GP_Gen5_2, GP_Gen5_4, GP_Gen5_6, GP_Gen5_8, GP_Gen5_10, GP_Gen5_12, GP_Gen5_14, GP_Gen5_16, GP_Gen5_18, GP_Gen5_20, GP_Gen5_24, GP_Gen5_32, GP_Gen5_40, GP_Gen5_80, BC_Gen5_2, BC_Gen5_4, BC_Gen5_6, BC_Gen5_8, BC_Gen5_10, BC_Gen5_12, BC_Gen5_14, BC_Gen5_16, BC_Gen5_18, BC_Gen5_20, BC_Gen5_24, BC_Gen5_32, BC_Gen5_40, BC_Gen5_80, HS_Gen5_2, HS_Gen5_4, HS_Gen5_6, HS_Gen5_8, HS_Gen5_10, HS_Gen5_12, HS_Gen5_14, HS_Gen5_16, HS_Gen5_18, HS_Gen5_20, HS_Gen5_24, HS_Gen5_32, HS_Gen5_40 and HS_Gen5_80. Mutually exclusive with elastic_pool_name.
# elastic_pool_name - (Optional) The name of SQL elastic pool where the database will be created for the SSIS catalog. Mutually exclusive with pricing_tier.
# dual_standby_pair_name - (Optional) The dual standby Azure-SSIS Integration Runtime pair with SSISDB failover.

# A custom_setup_script block supports the following:
# blob_container_uri - (Required) The blob endpoint for the container which contains a custom setup script that will be run on every node on startup. See https://docs.microsoft.com/azure/data-factory/how-to-configure-azure-ssis-ir-custom-setup for more information.
# sas_token - (Required) A container SAS token that gives access to the files. See https://docs.microsoft.com/azure/data-factory/how-to-configure-azure-ssis-ir-custom-setup for more information.

# An express_custom_setup block supports the following:
# command_key - (Optional) One or more command_key blocks as defined below.
# component - (Optional) One or more component blocks as defined below.
# environment - (Optional) The Environment Variables for the Azure-SSIS Integration Runtime.
# powershell_version - (Optional) The version of Azure Powershell installed for the Azure-SSIS Integration Runtime.

# A express_vnet_integration block supports the following:
# subnet_id - (Required) id of the subnet to which the nodes of the Azure-SSIS Integration Runtime will be added.

# A vnet_integration block supports the following:
# vnet_id - (Optional) ID of the virtual network to which the nodes of the Azure-SSIS Integration Runtime will be added.
# subnet_name - (Optional) Name of the subnet to which the nodes of the Azure-SSIS Integration Runtime will be added.
# subnet_id - (Optional) id of the subnet to which the nodes of the Azure-SSIS Integration Runtime will be added.
# public_ips - (Optional) Static public IP addresses for the Azure-SSIS Integration Runtime. The size must be 2.
# }

resource "azurerm_data_factory_integration_runtime_self_hosted" "default" {
  for_each        = { for key, value in var.irs : key => value if value.type == "Self-hosted" }
  name            = "${each.key}-adfirsh"
  description     = each.value.description
  data_factory_id = azurerm_data_factory.default.id

  # Creates a linked self-hosted IR
  dynamic "rbac_authorization" {
    for_each = each.value.rbac_resource_id == null ? [] : [for resource_id in each.value.rbac_resource_id : resource_id]
    content {
      resource_id = rbac_authorization.value
    }
  }
}

/*
Reference script: https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/quickstarts/microsoft.compute/vms-with-selfhost-integration-runtime/gatewayInstall.ps1

Create a container and upload the script to be installed on VMs

Initially I thought about running the script on VM from original location but it would require internet access from VMs, them I decided to upload it to a storage account
*/
data "azurerm_storage_account" "default" {
  count               = var.upload_script == null ? 0 : 1
  name                = split("/", var.upload_script.storage_account_id)[8]
  resource_group_name = split("/", var.upload_script.storage_account_id)[4]
}

resource "azurerm_storage_container" "default" {
  count                 = var.upload_script == null ? 0 : 1
  name                  = var.upload_script.container_name
  storage_account_name  = data.azurerm_storage_account.default[0].name
  container_access_type = "private"
}

resource "azurerm_storage_blob" "default" {
  count                  = var.upload_script == null ? 0 : 1
  name                   = "adf-shir-install.ps1"
  storage_account_name   = data.azurerm_storage_account.default[0].name
  storage_container_name = azurerm_storage_container.default[0].name
  type                   = "Block"
  source                 = "${path.module}/scripts/adf-shir-install.ps1"
}

# Create a list of nodes to install integration runtime
locals {
  nodes = flatten([for key, value in var.irs : [for key_node, value_node in value.nodes : {
    name        = key_node
    id          = value_node
    gateway_key = azurerm_data_factory_integration_runtime_self_hosted.default[key].primary_authorization_key
    }
  ] if value.type == "Self-hosted" && value.nodes != null])
}

resource "azurerm_virtual_machine_extension" "default" {
  for_each                   = { for key, value in local.nodes : value.name => value }
  name                       = "${each.key}-adfshir"
  virtual_machine_id         = each.value.id
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.10"
  auto_upgrade_minor_version = true

  protected_settings = <<PROTECTED_SETTINGS
      {
          "fileUris": ["${format("https://%s.blob.core.windows.net/%s/%s", data.azurerm_storage_account.default[0].name, azurerm_storage_container.default[0].name, azurerm_storage_blob.default[0].name)}"],
          "commandToExecute": "powershell.exe -ExecutionPolicy Unrestricted -File ${azurerm_storage_blob.default[0].name} ${each.value.gateway_key}",
          "storageAccountName": "${data.azurerm_storage_account.default[0].name}",
          "storageAccountKey": "${data.azurerm_storage_account.default[0].primary_access_key}"
      }
  PROTECTED_SETTINGS
}
