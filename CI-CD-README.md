# Resume Service - CI/CD Pipeline Documentation

A Spring Boot application with **separated CI (Continuous Integration)** and **manual CD (Continuous Deployment)** workflows for Azure Kubernetes Service (AKS).

## 🏗️ Pipeline Architecture

### **📦 CI Pipeline (Automated)**
- **Trigger**: Automatic on push to `main` or `develop` branches
- **Purpose**: Build, test, scan, and prepare artifacts
- **File**: `.github/workflows/ci-cd.yml`

### **🚀 CD Pipeline (Manual)**
- **Trigger**: Manual workflow dispatch with approval
- **Purpose**: Deploy to environments with your permission
- **File**: `.github/workflows/manual-deployment.yml`

### **🏷️ Release Pipeline (Manual)**
- **Trigger**: Manual workflow dispatch with approval
- **Purpose**: Create official releases
- **File**: `.github/workflows/create-release.yml`

## 🏗️ Architecture

- **Application**: Spring Boot 3.5.0 with Java 17
- **Infrastructure**: Azure Kubernetes Service (AKS) provisioned via Terraform
- **Container Registry**: Azure Container Registry (ACR)
- **CI/CD**: GitHub Actions with automated deployment
- **Environments**: Development and Production

## 📋 Prerequisites

### Local Development
- Java 17+
- Maven 3.6+
- Docker
- Azure CLI
- kubectl
- Terraform

### Azure Setup
- Azure subscription
- Service Principal with appropriate permissions
- Azure Container Registry

## 🚀 Quick Start

### 1. Run Locally
```bash
cd service
mvn spring-boot:run
```

Application will be available at `http://localhost:8080`

### 2. Build and Run with Docker
```bash
cd service
docker build -t resume-service .
docker run -p 8080:8080 resume-service
```

### 3. Deploy Infrastructure
```bash
cd infra/Terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values

terraform init
terraform plan
terraform apply
```

### 4. Deploy to Kubernetes
```bash
# Get AKS credentials
az aks get-credentials --resource-group <resource-group> --name <cluster-name>

# Deploy to dev
kubectl apply -k k8s/dev

# Deploy to prod
kubectl apply -k k8s/prod
```

## � **CI Pipeline (Automated)**

**Triggers**: Push to `main` or `develop` branches, Pull Requests

**What it does automatically**:
1. ✅ **Build and Test**: Maven build and unit tests
2. ✅ **Docker Build**: Multi-stage Docker build and push to ACR
3. ✅ **Infrastructure Validation**: Terraform format, init, and validate
4. ✅ **Kubernetes Validation**: Manifest validation with kubectl and kustomize
5. ✅ **Security Scanning**: Container vulnerability scanning with Trivy
6. ✅ **Artifact Publishing**: Creates deployment packages with all necessary files

**Outputs**:
- ✅ Docker images in ACR with tags like `main-abc123` or `develop-def456`
- ✅ Deployment artifacts for manual deployment
- ✅ Security scan results
- ✅ Build information and logs

## 🎯 **Manual Deployment Workflow**

**Trigger**: Manual workflow dispatch (requires your approval)

**How to use**:
1. Go to **Actions** tab in GitHub
2. Select **"Manual Deployment to Environments"**
3. Click **"Run workflow"**
4. Fill in the parameters:
   - **Environment**: `dev` or `prod`
   - **Image Tag**: Docker image tag to deploy (e.g., `main-abc123`)
   - **Deploy Infrastructure**: Check if you want to run Terraform
   - **Deploy Application**: Check to deploy to Kubernetes

**What it does**:
1. 🏗️ **Infrastructure Deployment** (if selected): Runs Terraform to create/update AKS
2. 🚀 **Application Deployment**: Deploys your chosen Docker image to Kubernetes
3. ✅ **Verification**: Checks deployment status and pod health
4. 📋 **Summary**: Provides deployment summary and verification results

## 🏷️ **Release Creation Workflow**

**Trigger**: Manual workflow dispatch (requires your approval)

**How to use**:
1. Go to **Actions** tab in GitHub
2. Select **"Create Release"**
3. Click **"Run workflow"**
4. Fill in the parameters:
   - **Version**: Semantic version (e.g., `v1.0.0`)
   - **Environment**: Environment the release is based on
   - **Image Tag**: Docker image tag to include in release
   - **Release Notes**: Optional description of changes

**What it does**:
1. 🏷️ **Git Tag**: Creates a Git tag for the version
2. 📦 **Release Package**: Creates a complete deployment package
3. 📋 **GitHub Release**: Creates a GitHub release with assets
4. 📄 **Documentation**: Includes deployment instructions and image info

## 🏷️ Environments

### Development
- **Branch**: `develop`
- **Namespace**: `resume-service`
- **Replicas**: 2
- **Resources**: 256Mi RAM, 250m CPU

### Production
- **Branch**: `main`
- **Namespace**: `resume-service-prod`
- **Replicas**: 5
- **Resources**: 1Gi RAM, 1 CPU

## 📊 Monitoring

The application includes:
- Spring Boot Actuator endpoints
- Kubernetes health checks
- Horizontal Pod Autoscaler (HPA)
- Log Analytics integration

### Health Endpoints
- `/actuator/health` - Application health
- `/actuator/info` - Application info
- `/actuator/metrics` - Application metrics

## 🔒 Security

- Non-root container user
- Network policies for pod-to-pod communication
- RBAC for service accounts
- Container vulnerability scanning
- Secrets management via Kubernetes secrets

## 🌐 Networking

- **Service Type**: ClusterIP
- **Ingress**: NGINX Ingress Controller
- **Load Balancing**: Azure Load Balancer
- **Auto-scaling**: HPA based on CPU utilization (70%)

## 📁 Project Structure

```
Capstone-Project/
├── .github/workflows/          # GitHub Actions CI/CD
├── infra/Terraform/           # Infrastructure as Code
├── k8s/                       # Kubernetes manifests
│   ├── dev/                   # Development environment
│   └── prod/                  # Production environment
├── service/                   # Spring Boot application
└── deploy.sh                  # Deployment script
```

## 🔧 Troubleshooting

### Common Issues

1. **Pod CrashLoopBackOff**
   ```bash
   kubectl logs -f deployment/resume-service -n resume-service
   kubectl describe pod <pod-name> -n resume-service
   ```

2. **Image Pull Errors**
   ```bash
   # Check ACR authentication
   az acr login --name <registry-name>
   
   # Verify image exists
   az acr repository list --name <registry-name>
   ```

3. **Terraform State Issues**
   ```bash
   terraform refresh
   terraform state list
   ```

## 📈 Scaling

### Manual Scaling
```bash
kubectl scale deployment resume-service --replicas=5 -n resume-service
```

### Auto Scaling
HPA is configured to scale between 2-10 replicas based on CPU utilization.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License.

## 📞 Support

For support and questions, please open an issue in the GitHub repository.

## 📋 **Workflow Examples**

### **Example 1: Deploy to Development**
```
Workflow: Manual Deployment to Environments
Environment: dev
Image Tag: develop-a1b2c3d (from CI pipeline)
Deploy Infrastructure: ✅ (if first time)
Deploy Application: ✅
```

### **Example 2: Deploy to Production**
```
Workflow: Manual Deployment to Environments  
Environment: prod
Image Tag: main-x1y2z3a (from CI pipeline)
Deploy Infrastructure: ❌ (already exists)
Deploy Application: ✅
```

### **Example 3: Create Release**
```
Workflow: Create Release
Version: v1.0.0
Environment: prod
Image Tag: main-x1y2z3a
Release Notes: "Initial production release with user authentication"
```

## 🔐 **Required GitHub Secrets**

Configure these secrets in your GitHub repository settings (**Settings > Secrets and variables > Actions**):

### **AZURE_CREDENTIALS**
```json
{
  "clientId": "<service-principal-client-id>",
  "clientSecret": "<service-principal-client-secret>", 
  "subscriptionId": "<azure-subscription-id>",
  "tenantId": "<azure-tenant-id>"
}
```

### **AZURE_REGISTRY_USERNAME**
- Your Azure Container Registry admin username

### **AZURE_REGISTRY_PASSWORD**  
- Your Azure Container Registry admin password

## 🔑 **Creating Azure Service Principal**

```bash
# Create service principal with contributor role
az ad sp create-for-rbac --name "resume-service-sp" --role contributor \
  --scopes /subscriptions/<subscription-id> \
  --sdk-auth

# Output will be the JSON for AZURE_CREDENTIALS secret
```

## 🎯 **Typical Development Workflow**

1. **Development Phase**:
   ```bash
   git checkout develop
   git add .
   git commit -m "Add new feature"
   git push origin develop
   ```
   → Triggers CI pipeline → Builds `develop-abc123` image

2. **Deploy to Dev** (Manual):
   - Go to Actions → Manual Deployment
   - Environment: `dev`
   - Image Tag: `develop-abc123`
   - Deploy!

3. **Production Release**:
   ```bash
   git checkout main  
   git merge develop
   git push origin main
   ```
   → Triggers CI pipeline → Builds `main-xyz789` image

4. **Deploy to Prod** (Manual):
   - Go to Actions → Manual Deployment
   - Environment: `prod`
   - Image Tag: `main-xyz789`
   - Deploy!

5. **Create Release** (Manual):
   - Go to Actions → Create Release
   - Version: `v1.1.0`
   - Image Tag: `main-xyz789`
   - Create Release!

## ✅ **Benefits of This Approach**

- 🔒 **Security**: No automatic deployments - you control when and what gets deployed
- 🎯 **Flexibility**: Deploy any image tag to any environment
- 📦 **Artifact Management**: CI creates tested, scanned images ready for deployment
- 🔍 **Traceability**: Every deployment is logged with image tags and approval
- 🚀 **Speed**: CI is fast (just build/test), deployments are separate
- 📋 **Documentation**: Every release has complete deployment packages
