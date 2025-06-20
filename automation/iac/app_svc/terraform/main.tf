# Main Terraform configuration for Azure AKS and ACR
# This creates a single AKS cluster with max 4 CPUs and an Azure Container Registry

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location

  tags = local.common_tags
}

# Virtual Network
resource "azurerm_virtual_network" "main" {
  name                = local.vnet_name
  address_space       = var.vnet_address_space
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = local.common_tags
}

# Subnet for AKS
resource "azurerm_subnet" "aks" {
  name                 = local.aks_subnet_name
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.subnet_address_prefix]
}

# Network Security Group for AKS subnet
resource "azurerm_network_security_group" "aks" {
  name                = local.nsg_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  # Allow HTTPS
  security_rule {
    name                       = "HTTPS"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Allow HTTP
  security_rule {
    name                       = "HTTP"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = local.common_tags
}

# Associate NSG with subnet
resource "azurerm_subnet_network_security_group_association" "aks" {
  subnet_id                 = azurerm_subnet.aks.id
  network_security_group_id = azurerm_network_security_group.aks.id
}

# Log Analytics Workspace for AKS monitoring
resource "azurerm_log_analytics_workspace" "aks" {
  name                = local.log_analytics_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = var.environment == "production" ? 90 : 30

  tags = local.common_tags
}

# Azure Kubernetes Service
resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.aks_cluster_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  dns_prefix          = local.aks_dns_prefix
  kubernetes_version  = var.kubernetes_version

  default_node_pool {
    name                 = "default"
    node_count           = var.node_count
    vm_size              = var.node_vm_size
    auto_scaling_enabled = var.enable_auto_scaling
    min_count            = var.min_node_count
    max_count            = var.max_node_count
    max_pods             = local.current_env_config.max_pods
    os_disk_size_gb      = local.current_env_config.disk_size
    vnet_subnet_id       = azurerm_subnet.aks.id
    
    # Use availability zones for high availability
    zones = ["1", "2", "3"]

    upgrade_settings {
      max_surge = "10%"
    }
  }

  identity {
    type = "SystemAssigned"
  }

  # Enable monitoring
  dynamic "oms_agent" {
    for_each = var.enable_monitoring ? [1] : []
    content {
      log_analytics_workspace_id = azurerm_log_analytics_workspace.aks.id
    }
  }

  # Network configuration
  network_profile {
    network_plugin    = "azure"
    network_policy    = "azure"
    load_balancer_sku = "standard"
    dns_service_ip    = var.dns_service_ip
    service_cidr      = var.service_cidr
  }

  # API Server configuration
  dynamic "api_server_access_profile" {
    for_each = length(var.authorized_ip_ranges) > 0 ? [1] : []
    content {
      authorized_ip_ranges = var.authorized_ip_ranges
    }
  }

  # Security and compliance
  role_based_access_control_enabled = true

  # Azure Policy Add-on
  azure_policy_enabled = var.environment == "production"

  # HTTP Application Routing (disabled for production)
  http_application_routing_enabled = var.environment != "production"

  tags = local.common_tags
}

# Grant AKS access to ACR
resource "azurerm_role_assignment" "aks_acr_pull" {
  principal_id                     = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                           = data.azurerm_container_registry.existing_acr.id
  skip_service_principal_aad_check = true
}

# Grant AKS access to the subnet
resource "azurerm_role_assignment" "aks_subnet" {
  principal_id         = azurerm_kubernetes_cluster.aks.identity[0].principal_id
  role_definition_name = "Network Contributor"
  scope                = azurerm_subnet.aks.id
}

# Additional node pool for production workloads (optional)
resource "azurerm_kubernetes_cluster_node_pool" "production" {
  count                 = var.enable_production_node_pool ? 1 : 0
  name                  = "production"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  vm_size              = "Standard_D2s_v3"
  node_count           = 1
  auto_scaling_enabled = true
  min_count            = 1
  max_count            = 1  # Keep within CPU limits
  max_pods             = 30
  vnet_subnet_id       = azurerm_subnet.aks.id
  zones                = ["1", "2", "3"]

  node_labels = {
    "workload" = "production"
  }

  node_taints = [
    "workload=production:NoSchedule"
  ]

  tags = local.common_tags
}
