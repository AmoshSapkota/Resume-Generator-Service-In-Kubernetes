# Production environment Terraform variable values

# Resource naming
resource_group_name = "rg-resume-service-prod"
location           = "East US"
environment        = "production"
project_name       = "ResumeService"

# Azure Container Registry
acr_name = "acrresumeserviceprod"

# AKS Configuration
aks_cluster_name   = "aks-resume-service-prod"
kubernetes_version = "1.28.5"

# Node pool configuration (keeping within 4 CPU limit)
node_count      = 2
node_vm_size    = "Standard_D2s_v3"  # 2 vCPUs, 8 GB RAM each
max_node_count  = 2  # Maximum 2 nodes = 4 vCPUs total
min_node_count  = 1

# Features
enable_production_node_pool = false  # Disabled to stay within CPU limit
enable_monitoring          = true
enable_auto_scaling        = true

# Key Vault
key_vault_name = "kv-resume-service-prod"

# Network configuration
vnet_address_space     = ["10.0.0.0/16"]
subnet_address_prefix  = "10.0.1.0/24"
dns_service_ip        = "10.0.0.10"
service_cidr          = "10.0.0.0/24"

# Backup and disaster recovery
enable_backup = true
backup_retention_days = 30

# Security
enable_private_cluster = false  # Set to true for enhanced security
authorized_ip_ranges   = []     # Add your IP ranges for API server access

# Tags
tags = {
  Environment = "Production"
  Project     = "ResumeService"
  ManagedBy   = "Terraform"
  CostCenter  = "Production"
  Owner       = "DevOps Team"
  Compliance  = "Required"
}
