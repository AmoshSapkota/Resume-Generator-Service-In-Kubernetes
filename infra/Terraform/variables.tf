# Variables for Resume Service AKS Infrastructure

variable "azure_location" {
  description = "The Azure region where resources will be created"
  type        = string
  default     = "East US"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "resume-service"
}

variable "vnet_cidr" {
  description = "CIDR block for Virtual Network"
  type        = string
  default     = "10.0.0.0/16"
}

variable "aks_subnet_cidr" {
  description = "CIDR block for AKS subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "container_port" {
  description = "Port exposed by the docker image to redirect traffic to"
  type        = number
  default     = 8080
}

# AKS Cluster Variables
variable "kubernetes_version" {
  description = "Kubernetes version for the AKS cluster"
  type        = string
  default     = "1.27"
}

variable "kubernetes_namespace" {
  description = "Kubernetes namespace for the application"
  type        = string
  default     = "resume-service"
}

# AKS Node Pool Variables
variable "node_count" {
  description = "Initial number of nodes in the AKS node pool"
  type        = number
  default     = 2
}

variable "node_vm_size" {
  description = "VM size for AKS nodes"
  type        = string
  default     = "Standard_D2s_v3"
}

variable "node_min_count" {
  description = "Minimum number of nodes in the AKS node pool"
  type        = number
  default     = 1
}

variable "node_max_count" {
  description = "Maximum number of nodes in the AKS node pool"
  type        = number
  default     = 5
}

# Azure Container Registry Variables
variable "acr_sku" {
  description = "SKU for Azure Container Registry"
  type        = string
  default     = "Standard"
  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.acr_sku)
    error_message = "ACR SKU must be Basic, Standard, or Premium."
  }
}

# Application Variables
variable "app_count" {
  description = "Number of docker containers to run"
  type        = number
  default     = 2
}

# Logging Variables
variable "log_retention_days" {
  description = "Log Analytics workspace retention in days"
  type        = number
  default     = 30
}

variable "health_check_path" {
  description = "Health check path for the load balancer"
  type        = string
  default     = "/actuator/health"
}

variable "health_check_matcher" {
  description = "HTTP response codes to indicate a healthy check"
  type        = string
  default     = "200"
}
