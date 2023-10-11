variable "location" {
  description = "The region where the Data Factory will be created. This parameter is required"
  type        = string
  default     = "northeurope"
  nullable    = false
}

variable "resource_group_name" {
  description = "The name of the resource group in which the resources will be created. This parameter is required"
  type        = string
  nullable    = false
}

variable "tags" {
  description = "Tags to be applied to resources."
  type        = map(string)
  default     = null
}

variable "data_factory" {
  type = object({
    name                             = string
    managed_virtual_network_enabled  = optional(bool, true)
    public_network_enabled           = optional(bool, true)
    customer_managed_key_id          = optional(string, null)
    customer_managed_key_identity_id = optional(string, null)
    purview_id                       = optional(string, null)

    github_configuration = optional(object({
      account_name       = string
      repository_name    = string
      branch_name        = optional(string, "dev")
      git_url            = optional(string, "https://github.com")
      root_folder        = optional(string, "/adf")
      publishing_enabled = optional(bool, false)
    }), null)

    vsts_configuration = optional(object({
      account_name       = string
      repository_name    = string
      project_name       = string
      tenant_id          = string
      branch_name        = optional(string, "dev")
      root_folder        = optional(string, "/adf")
      publishing_enabled = optional(bool, false)
    }), null)

    identity = optional(object({
      type         = optional(string, "SystemAssigned")
      identity_ids = optional(list(string), null)
    }), {})

    global_parameter = optional(map(object({
      type  = optional(string, "String")
      value = string
    })), null)
  })
  nullable = false
}

variable "managed_private_endpoints" {
  type = map(object({
    target_resource_id = string
    subresource_name   = string
  }))
  default = null
}
