output "id" {
  value = azurerm_data_factory.default.id
}

output "name" {
  value = azurerm_data_factory.default.name
}

output "self_hosted_ir_ids" {
  value = { for key, value in azurerm_data_factory_integration_runtime_self_hosted.default : value.name => value.id }
}

output "azure_ir_ids" {
  value = { for key, value in azurerm_data_factory_integration_runtime_azure.default : value.name => value.id }
}

output "self_hosted_ir_keys" {
  value = { for key, value in azurerm_data_factory_integration_runtime_self_hosted.default : value.name => { primary_authorization_key = value.primary_authorization_key, secondary_authorization_key = value.secondary_authorization_key } }
}

output "identity" {
  value = azurerm_data_factory.default.identity
}
