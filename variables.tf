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

variable "name_sufix_append" {
  description = "Define if all resources names should be appended with sufixes according to https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-abbreviations."
  type        = bool
  default     = true
  nullable    = false
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

variable "upload_script" {
  type = object({
    storage_account_id = string
    container_name     = optional(string, "adf-scripts")
  })
  default = null
}

variable "irs" {
  type = map(object({
    description             = optional(string, null)
    type                    = optional(string, "Azure")
    location                = optional(string, "AutoResolve")
    compute_type            = optional(string, "General")
    core_count              = optional(number, 8)
    time_to_live_min        = optional(number, 0)
    cleanup_enabled         = optional(bool, true)
    virtual_network_enabled = optional(bool, true)
    rbac_resource_id        = optional(list(string), null)
    nodes                   = optional(map(string), null)
  }))
  default = {}

  nullable = false

  validation {
    condition     = var.irs != null ? alltrue([for ir in var.irs : can(index(["Azure", "Self-hosted"], ir.type) >= 0)]) : true
    error_message = "Allowed values for type are Azure and Self-hosted"
  }

  validation {
    condition     = var.irs != null ? alltrue([for ir in var.irs : can(index(["General", "ComputeOptimized", "MemoryOptimized"], ir.compute_type) >= 0)]) : true
    error_message = "Allowed values for compute_type are General, ComputeOptimized and MemoryOptimized"
  }
}

variable "private_endpoints" {
  type = map(object({
    name                           = string
    subnet_id                      = string
    application_security_group_ids = optional(list(string))
    private_dns_zone_id            = string
  }))

  default = null
}
