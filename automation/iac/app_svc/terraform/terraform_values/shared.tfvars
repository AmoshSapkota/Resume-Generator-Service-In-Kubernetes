# automation/iac/app_svc/terraform/terraform_values/shared.tfvars (NEW)
environment = "shared"
resource_group_name = "rg-resume-shared"
aks_cluster_name = "aks-resume-shared"
node_count = 2                        # Bigger for both environments
acr_name = "amoshacr"
acr_resource_group_name = "Amosh_group"
location = "East US"
node_vm_size = "Standard_B2s"        # Larger VM to handle both environments
project_name = "resume"