# Outputs for Resume Service AKS Infrastructure

# Resource Group
output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "resource_group_location" {
  description = "Location of the resource group"
  value       = azurerm_resource_group.main.location
}

# Virtual Network
output "vnet_id" {
  description = "ID of the Virtual Network"
  value       = azurerm_virtual_network.main.id
}

output "vnet_name" {
  description = "Name of the Virtual Network"
  value       = azurerm_virtual_network.main.name
}

output "aks_subnet_id" {
  description = "ID of the AKS subnet"
  value       = azurerm_subnet.aks.id
}

# AKS Cluster Outputs
output "cluster_id" {
  description = "AKS cluster ID"
  value       = azurerm_kubernetes_cluster.main.id
}

output "cluster_name" {
  description = "AKS cluster name"
  value       = azurerm_kubernetes_cluster.main.name
}

output "cluster_endpoint" {
  description = "Endpoint for AKS control plane"
  value       = azurerm_kubernetes_cluster.main.kube_config.0.host
}

output "cluster_fqdn" {
  description = "FQDN of the AKS cluster"
  value       = azurerm_kubernetes_cluster.main.fqdn
}

output "cluster_node_resource_group" {
  description = "Auto-generated resource group which contains the resources for this managed Kubernetes cluster"
  value       = azurerm_kubernetes_cluster.main.node_resource_group
}

# Container Registry Outputs
output "acr_id" {
  description = "ID of the Azure Container Registry"
  value       = azurerm_container_registry.main.id
}

output "acr_name" {
  description = "Name of the Azure Container Registry"
  value       = azurerm_container_registry.main.name
}

output "acr_login_server" {
  description = "Login server URL of the Azure Container Registry"
  value       = azurerm_container_registry.main.login_server
}

output "acr_admin_username" {
  description = "Admin username for the Azure Container Registry"
  value       = azurerm_container_registry.main.admin_username
  sensitive   = true
}

output "acr_admin_password" {
  description = "Admin password for the Azure Container Registry"
  value       = azurerm_container_registry.main.admin_password
  sensitive   = true
}

# Kubernetes Namespace
output "kubernetes_namespace" {
  description = "Kubernetes namespace name"
  value       = kubernetes_namespace.resume_service.metadata[0].name
}

# Log Analytics Workspace
output "log_analytics_workspace_id" {
  description = "ID of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.main.id
}

output "log_analytics_workspace_name" {
  description = "Name of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.main.name
}

# Useful kubectl commands
output "kubectl_config_command" {
  description = "Command to configure kubectl"
  value       = "az aks get-credentials --resource-group ${azurerm_resource_group.main.name} --name ${azurerm_kubernetes_cluster.main.name}"
}

output "kubectl_get_nodes_command" {
  description = "Command to get cluster nodes"
  value       = "kubectl get nodes"
}

output "kubectl_get_pods_command" {
  description = "Command to get pods in the application namespace"
  value       = "kubectl get pods -n ${var.kubernetes_namespace}"
}

# CI/CD related outputs
output "acr_login_command" {
  description = "Command to login to Azure Container Registry"
  value       = "az acr login --name ${azurerm_container_registry.main.name}"
}

output "docker_build_command" {
  description = "Command to build and tag Docker image"
  value       = "docker build -t ${azurerm_container_registry.main.login_server}/resume-service:latest ."
}

output "docker_push_command" {
  description = "Command to push Docker image to ACR"
  value       = "docker push ${azurerm_container_registry.main.login_server}/resume-service:latest"
}

output "kustomize_build_dev_command" {
  description = "Command to build Kubernetes manifests for dev environment"
  value       = "kubectl apply -k k8s/dev"
}

output "kustomize_build_prod_command" {
  description = "Command to build Kubernetes manifests for prod environment"
  value       = "kubectl apply -k k8s/prod"
}

# Azure CLI commands
output "az_aks_show_command" {
  description = "Command to show AKS cluster details"
  value       = "az aks show --resource-group ${azurerm_resource_group.main.name} --name ${azurerm_kubernetes_cluster.main.name}"
}

output "az_acr_repository_list_command" {
  description = "Command to list ACR repositories"
  value       = "az acr repository list --name ${azurerm_container_registry.main.name}"
}
