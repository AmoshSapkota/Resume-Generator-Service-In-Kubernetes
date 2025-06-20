# Test environment Terraform variable values

# Resource naming
resource_group_name = "rg-resume-service-test"
location           = "East US"
environment        = "test"
project_name       = "ResumeService"

# Azure Container Registry
acr_name = "acrresumeservicetest"

# AKS Configuration
aks_cluster_name   = "aks-resume-service-test"
kubernetes_version = "1.28.5"

# Node pool configuration (keeping within 4 CPU limit)
node_count      = 1
node_vm_size    = "Standard_D2s_v3"  # 2 vCPUs, 8 GB RAM
max_node_count  = 2
min_node_count  = 1

# Features
enable_production_node_pool = false
enable_monitoring          = true
enable_auto_scaling        = true

# Key Vault
key_vault_name = "kv-resume-service-test"

# Network configuration
vnet_address_space     = ["10.1.0.0/16"]
subnet_address_prefix  = "10.1.1.0/24"
dns_service_ip        = "10.1.0.10"
service_cidr          = "10.1.0.0/24"

# Tags
tags = {
  Environment = "Test"
  Project     = "ResumeService"
  ManagedBy   = "Terraform"
  CostCenter  = "Development"
  Owner       = "DevOps Team"
}
