environment = "prod"
resource_group_name = "rg-resume-prod"
aks_cluster_name = "aks-resume-prod"
node_count = 2
acr_name = "amoshacr"
acr_resource_group_name = "rg-resume-shared"

tags = {
  Environment = "production"
  Owner = "amosh"
}