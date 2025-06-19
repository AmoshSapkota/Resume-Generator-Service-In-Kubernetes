# Step-by-Step Deployment Guide

## 🚀 Complete Deployment Process

### **Phase 1: Infrastructure Setup (Terraform creates AKS + ACR automatically)**

1. **Login to Azure**
   ```powershell
   az login
   ```

2. **Configure Terraform Variables**
   ```powershell
   cd infra\Terraform
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your values
   ```

3. **Deploy Infrastructure (Creates AKS + ACR automatically)**
   ```powershell
   terraform init
   terraform plan
   terraform apply
   ```
   ✅ **This automatically creates:**
   - Azure Resource Group
   - AKS Cluster (Kubernetes)
   - ACR (Container Registry)
   - Virtual Network
   - All necessary permissions

### **Phase 2: Build and Push Docker Image to ACR**

4. **Get ACR Login Details**
   ```powershell
   # Get ACR name from Terraform output
   $ACR_NAME = terraform output -raw acr_name
   $ACR_LOGIN_SERVER = terraform output -raw acr_login_server
   
   # Login to ACR
   az acr login --name $ACR_NAME
   ```

5. **Build and Push Docker Image**
   ```powershell
   cd ..\..\service
   
   # Build the image
   docker build -t resume-service .
   
   # Tag for ACR
   docker tag resume-service:latest "${ACR_LOGIN_SERVER}/resume-service:latest"
   
   # Push to ACR
   docker push "${ACR_LOGIN_SERVER}/resume-service:latest"
   ```

### **Phase 3: Deploy to Kubernetes**

6. **Connect to AKS**
   ```powershell
   cd ..
   
   # Get AKS credentials
   $RESOURCE_GROUP = terraform -chdir=infra/Terraform output -raw resource_group_name
   $CLUSTER_NAME = terraform -chdir=infra/Terraform output -raw cluster_name
   
   az aks get-credentials --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME
   ```

7. **Update Kubernetes Manifests with Correct Image**
   ```powershell
   # Update dev environment
   cd k8s\dev
   
   # Edit kustomization.yaml to use correct image
   # Change the image name to: your-acr-name.azurecr.io/resume-service:latest
   ```

8. **Deploy to Kubernetes**
   ```powershell
   # Deploy to dev environment
   kubectl apply -k .
   
   # Check deployment status
   kubectl get pods -n resume-service
   kubectl get services -n resume-service
   ```

## 🔧 **What Each Tool Does:**

- **Terraform** = Creates Azure infrastructure (AKS cluster + ACR registry)
- **Docker** = Builds your application image and pushes to ACR
- **Kubectl** = Deploys your application to the AKS cluster

## 💡 **Key Points:**

1. ✅ **AKS is created automatically** by Terraform
2. ✅ **ACR is created automatically** by Terraform  
3. ✅ **Permissions are set automatically** by Terraform
4. ❌ **You need to manually build and push the Docker image**
5. ❌ **You need to manually deploy to Kubernetes**

## 🎯 **Quick Commands Summary:**

```powershell
# 1. Deploy infrastructure
cd infra\Terraform
terraform apply

# 2. Build and push image
$ACR_NAME = terraform output -raw acr_name
az acr login --name $ACR_NAME
cd ..\..\service
docker build -t resume-service .
docker tag resume-service:latest "$ACR_NAME.azurecr.io/resume-service:latest"
docker push "$ACR_NAME.azurecr.io/resume-service:latest"

# 3. Deploy to Kubernetes
cd ..\k8s\dev
kubectl apply -k .
```

## 🚨 **Important Notes:**

- Make sure Docker Desktop is running
- Make sure you have kubectl installed (`az aks install-cli`)
- The CI/CD pipeline will automate steps 2-3 when you push to GitHub
