# Local values for resource naming and configuration
locals {
  # Common tags to be assigned to all resources
  common_tags = merge(
    var.tags,
    {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "Terraform"
      CreatedDate = formatdate("YYYY-MM-DD", timestamp())
    }
  )

  # Resource naming convention
  resource_prefix = "${var.project_name}-${var.environment}"
  
  # Generate unique suffix for globally unique resources
  unique_suffix = random_string.unique_suffix.result
  
  # ACR name (must be globally unique and alphanumeric only)
  acr_name = "${replace(lower(var.acr_name), "-", "")}"
  
  # Key Vault name (must be globally unique)
  key_vault_name = "${var.key_vault_name}-${local.unique_suffix}"
  
  # Network configuration
  vnet_name               = "${local.resource_prefix}-vnet"
  subnet_name            = "${local.resource_prefix}-subnet"
  aks_subnet_name        = "${local.resource_prefix}-aks-subnet"
  
  # AKS configuration
  aks_dns_prefix = "${replace(lower(var.aks_cluster_name), "_", "-")}"
  
  # Log Analytics workspace name
  log_analytics_name = "${var.aks_cluster_name}-logs"
  
  # Network security group
  nsg_name = "${local.resource_prefix}-nsg"
  
  # Application Gateway (if needed)
  app_gateway_name = "${local.resource_prefix}-appgw"
  
  # Storage account for diagnostics
  storage_account_name = "${replace(lower(local.resource_prefix), "-", "")}storage${local.unique_suffix}"
  
  # Kubernetes namespaces
  k8s_namespaces = {
    test = "resume-test"
    prod = "resume-prod"
  }
  
  # Environment-specific configurations
  environment_config = {
    test = {
      node_count     = 1
      min_nodes      = 1
      max_nodes      = 2
      vm_size        = "Standard_D2s_v3"
      disk_size      = 30
      max_pods       = 30
    }
    production = {
      node_count     = 2
      min_nodes      = 1
      max_nodes      = 2
      vm_size        = "Standard_D2s_v3"
      disk_size      = 50
      max_pods       = 50
    }
  }
  
  # Get current environment config
  current_env_config = local.environment_config[var.environment]
}
