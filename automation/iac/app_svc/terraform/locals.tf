locals {
  name_prefix = "${var.project_name}-${var.environment}"
  
  aks_dns_prefix     = "${var.project_name}${var.environment}"
  
  common_tags = merge(var.tags, {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  })
  
  retention_days = var.environment == "prod" ? 90 : 30
}