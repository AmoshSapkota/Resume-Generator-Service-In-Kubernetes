# Variables for Terraform AKS and ACR configuration

variable "resource_group_name" {
  description = "Name of the Azure Resource Group"
  type        = string
  default     = "Amosh_group"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "East US"
}

variable "acr_name" {
  description = "Name of the Azure Container Registry (will have random suffix)"
  type        = string
  default     = "acrresumeservice"
}

variable "aks_cluster_name" {
  description = "Name of the AKS cluster"
  type        = string
  default     = "aks-resume-service"
}

variable "kubernetes_version" {
  description = "Kubernetes version for AKS cluster"
  type        = string
  default     = "1.28.5"
}

variable "node_count" {
  description = "Number of nodes in the default node pool"
  type        = number
  default     = 2
}

variable "node_vm_size" {
  description = "VM size for AKS nodes (max 4 CPUs total)"
  type        = string
  default     = "Standard_D2s_v3"  # 2 vCPUs, 8 GB RAM
}

variable "min_node_count" {
  description = "Minimum number of nodes in the node pool"
  type        = number
  default     = 1
}

variable "max_node_count" {
  description = "Maximum number of nodes in the node pool"
  type        = number
  default     = 2
}

variable "enable_production_node_pool" {
  description = "Enable production node pool"
  type        = bool
  default     = false
}

variable "key_vault_name" {
  description = "Name of the Azure Key Vault (will have random suffix)"
  type        = string
  default     = "kv-resume-service"
}

variable "environment" {
  description = "Environment tag"
  type        = string
  default     = "test"
  
  validation {
    condition     = contains(["test", "production"], var.environment)
    error_message = "Environment must be one of: test, production."
  }
}

variable "project_name" {
  description = "Project name tag"
  type        = string
  default     = "ResumeService"
}

variable "tags" {
  description = "A map of tags to assign to the resources"
  type        = map(string)
  default     = {}
}

# Network variables
variable "vnet_address_space" {
  description = "Address space for the virtual network"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "subnet_address_prefix" {
  description = "Address prefix for the subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "dns_service_ip" {
  description = "DNS service IP address"
  type        = string
  default     = "10.1.0.10"
}

variable "service_cidr" {
  description = "Service CIDR for Kubernetes services"
  type        = string
  default     = "10.1.0.0/24"
}

# Security variables
variable "acr_allowed_ips" {
  description = "List of IP addresses allowed to access ACR"
  type        = list(string)
  default     = []
}

variable "key_vault_allowed_ips" {
  description = "List of IP addresses allowed to access Key Vault"
  type        = list(string)
  default     = []
}

variable "authorized_ip_ranges" {
  description = "List of authorized IP ranges for AKS API server"
  type        = list(string)
  default     = []
}

# Feature flags
variable "enable_monitoring" {
  description = "Enable Azure Monitor for the AKS cluster"
  type        = bool
  default     = true
}

variable "enable_auto_scaling" {
  description = "Enable auto scaling for the node pool"
  type        = bool
  default     = true
}

variable "enable_backup" {
  description = "Enable backup for production environment"
  type        = bool
  default     = false
}

variable "backup_retention_days" {
  description = "Number of days to retain backups"
  type        = number
  default     = 30
}

variable "enable_private_cluster" {
  description = "Enable private cluster for AKS"
  type        = bool
  default     = false
}

# ACR Georeplications
variable "acr_georeplications" {
  description = "List of ACR georeplications for production"
  type = list(object({
    location                = string
    zone_redundancy_enabled = bool
  }))
  default = []
}

# CORS settings
variable "cors_allowed_origins" {
  description = "List of allowed origins for CORS"
  type        = list(string)
  default     = ["*"]
}
