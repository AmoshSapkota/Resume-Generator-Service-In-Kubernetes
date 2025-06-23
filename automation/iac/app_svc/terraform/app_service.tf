# Azure Container Registry and related app service resources

# Random string for unique naming
resource "random_string" "unique_suffix" {
  length  = 4
  special = false
  upper   = false
  numeric = true
}

# Data source for current client configuration
data "azurerm_client_config" "current" {}

# Azure Container Registry - COMMENTED OUT (using existing manual ACR: amoshacr)
# resource "azurerm_container_registry" "acr" {
#   name                = "${local.acr_name}${local.unique_suffix}"
#   resource_group_name = azurerm_resource_group.main.name
#   location            = azurerm_resource_group.main.location
#   sku                 = var.environment == "production" ? "Premium" : "Standard"
#   admin_enabled       = true

#   # Network rules for production
#   dynamic "network_rule_set" {
#     for_each = var.environment == "production" ? [1] : []
#     content {
#       default_action = "Allow"
      
#       # Add IP rules if specified
#       dynamic "ip_rule" {
#         for_each = var.acr_allowed_ips
#         content {
#           action   = "Allow"
#           ip_range = ip_rule.value
#         }
#       }
#     }
#   }

#   # Enable georeplications for production
#   dynamic "georeplications" {
#     for_each = var.environment == "production" ? var.acr_georeplications : []
#     content {
#       location                = georeplications.value.location
#       zone_redundancy_enabled = georeplications.value.zone_redundancy_enabled
#       tags                    = local.common_tags
#     }
#   }

#   tags = local.common_tags
# }

# Data source for existing ACR (manually created)
data "azurerm_container_registry" "existing_acr" {
  name                = "amoshacr"
  resource_group_name = "Amosh_group"
}

# Storage account for application data and backups
resource "azurerm_storage_account" "app_storage" {
  name                     = local.storage_account_name
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = var.environment == "production" ? "GRS" : "LRS"
  
  # Security settings
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  
  # Blob properties
  blob_properties {
    cors_rule {
      allowed_headers    = ["*"]
      allowed_methods    = ["GET", "HEAD"]
      allowed_origins    = var.cors_allowed_origins
      exposed_headers    = ["*"]
      max_age_in_seconds = 3600
    }

    delete_retention_policy {
      days = var.environment == "production" ? 30 : 7
    }

    versioning_enabled = var.environment == "production"
  }

  tags = local.common_tags
}

# Storage container for application files
resource "azurerm_storage_container" "app_files" {
  name               = "app-files"
  storage_account_id = azurerm_storage_account.app_storage.id
}

# Storage container for backups
resource "azurerm_storage_container" "backups" {
  name               = "backups"
  storage_account_id = azurerm_storage_account.app_storage.id
}

# Application Insights for monitoring
resource "azurerm_application_insights" "app_insights" {
  name                = "${local.resource_prefix}-appinsights"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  workspace_id        = azurerm_log_analytics_workspace.aks.id
  application_type    = "web"
  
  # Retention period
  retention_in_days = var.environment == "production" ? 90 : 30
  
  tags = local.common_tags
}

# Azure Key Vault for storing application secrets
resource "azurerm_key_vault" "app_vault" {
  name                        = local.key_vault_name
  location                    = azurerm_resource_group.main.location
  resource_group_name         = azurerm_resource_group.main.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = var.environment == "production"
  sku_name                    = "standard"

  # Network ACLs for production
  network_acls {
    bypass                     = "AzureServices"
    default_action             = var.environment == "production" ? "Deny" : "Allow"
    ip_rules                   = var.key_vault_allowed_ips
    virtual_network_subnet_ids = var.environment == "production" ? [azurerm_subnet.aks.id] : []
  }

  tags = local.common_tags
}

# Key Vault access policy for current user/service principal
resource "azurerm_key_vault_access_policy" "current_user" {
  key_vault_id = azurerm_key_vault.app_vault.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  key_permissions = [
    "Get", "List", "Update", "Create", "Import", "Delete", "Recover", "Backup", "Restore"
  ]

  secret_permissions = [
    "Get", "List", "Set", "Delete", "Recover", "Backup", "Restore"
  ]

  certificate_permissions = [
    "Get", "List", "Update", "Create", "Import", "Delete", "Recover", "ManageContacts", "ManageIssuers"
  ]
}

# Key Vault access policy for AKS
resource "azurerm_key_vault_access_policy" "aks_policy" {
  key_vault_id = azurerm_key_vault.app_vault.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_kubernetes_cluster.aks.identity[0].principal_id

  secret_permissions = [
    "Get", "List"
  ]
}

# Store ACR credentials in Key Vault
resource "azurerm_key_vault_secret" "acr_username" {
  name         = "acr-username"
  value        = data.azurerm_container_registry.existing_acr.admin_username
  key_vault_id = azurerm_key_vault.app_vault.id
  
  depends_on = [azurerm_key_vault_access_policy.current_user]
}

resource "azurerm_key_vault_secret" "acr_password" {
  name         = "acr-password"
  value        = data.azurerm_container_registry.existing_acr.admin_password
  key_vault_id = azurerm_key_vault.app_vault.id
  
  depends_on = [azurerm_key_vault_access_policy.current_user]
}

# Store Application Insights connection string
resource "azurerm_key_vault_secret" "app_insights_connection_string" {
  name         = "app-insights-connection-string"
  value        = azurerm_application_insights.app_insights.connection_string
  key_vault_id = azurerm_key_vault.app_vault.id
  
  depends_on = [azurerm_key_vault_access_policy.current_user]
}
