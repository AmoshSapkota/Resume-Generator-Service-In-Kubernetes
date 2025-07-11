# Resume Service - Cloud-Native Application

A containerized Spring Boot application demonstrating modern DevOps practices with Azure cloud infrastructure, Kubernetes orchestration, and CI/CD automation.

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                     Azure Cloud Infrastructure                  │
├─────────────────────────────────────────────────────────────────┤
│  📦 Azure Container Registry (ACR)                             │
│  ├── amoshacr.azurecr.io/resume-service:latest                 │
│  └── amoshacr.azurecr.io/resume-service:{build-number}         │
├─────────────────────────────────────────────────────────────────┤
│  🏢 AKS Cluster: aks-resume-shared                             │
│  ├── 🏠 test namespace                                          │
│  │   ├── 📦 resume-service-deployment                          │
│  │   ├── 🌐 resume-service-lb (LoadBalancer)                  │
│  │   ├── ⚙️ resume-service-config (ConfigMap)                 │
│  │   └── 🔐 acr-auth (Docker Registry Secret)                 │
│  └── 🏠 prod namespace                                          │
│      ├── 📦 resume-service-deployment                          │
│      ├── 🌐 resume-service-lb (LoadBalancer)                  │
│      ├── ⚙️ resume-service-config (ConfigMap)                 │
│      └── 🔐 acr-auth (Docker Registry Secret)                 │
└─────────────────────────────────────────────────────────────────┘
```

## 🚀 Key Features

- **Multi-Environment Deployment**: Shared AKS cluster with namespace isolation
- **Container Orchestration**: Kubernetes-native deployment with auto-scaling capabilities
- **Infrastructure as Code**: Terraform-managed Azure resources
- **CI/CD Pipeline**: Automated build, test, and deployment workflows
- **Blue-Green Ready**: Build number tagging for reliable deployments
- **Cost-Optimized**: Shared infrastructure reducing operational expenses

## 🛠️ Technology Stack

### **Application Layer**
- **Framework**: Spring Boot 3.x
- **Language**: Java 17
- **Build Tool**: Maven
- **Container**: Docker multi-stage builds

### **Infrastructure Layer**
- **Cloud Provider**: Microsoft Azure
- **Container Registry**: Azure Container Registry (ACR)
- **Orchestration**: Azure Kubernetes Service (AKS)
- **Infrastructure**: Terraform
- **Compute**: Standard_B2s VMs (2 vCPUs, 4GB RAM)

### **DevOps Pipeline**
- **CI/CD**: Azure DevOps Pipelines
- **Configuration**: YAML-based pipeline definitions
- **Artifact Management**: Pipeline artifacts for k8s manifests
- **Image Management**: Build number tagging strategy

## 📁 Project Structure

```
Amosh%20Project/
├── app_svc/                           # Spring Boot Application
│   ├── src/main/java/                 # Java source code
│   ├── src/main/resources/            # Application resources
│   │   ├── application.properties     # Spring configuration
│   │   └── static/                    # Static web content
│   ├── Dockerfile                     # Multi-stage container build
│   └── pom.xml                        # Maven dependencies
├── automation/                        # DevOps Automation
│   ├── cicd/
│   │   └── ci-pipeline.yaml          # Azure DevOps CI pipeline
│   ├── iac/app_svc/terraform/         # Infrastructure as Code
│   │   ├── *.tf                      # Terraform modules
│   │   └── terraform_values/          # Environment configurations
│   │       ├── shared.tfvars         # Shared cluster config
│   │       ├── test.tfvars           # Test environment config
│   │       └── prod.tfvars           # Production environment config
│   └── k8s/manifests/                # Kubernetes Manifests
│       ├── namespace.yaml            # Namespace definitions
│       ├── deployment.yaml           # Application deployment
│       ├── service.yaml              # LoadBalancer service
│       └── config_map/               # Environment-specific configs
│           ├── test.yaml             # Test configuration
│           └── prod.yaml             # Production configuration
└── README.md                         # Project documentation
```

## 🏃‍♂️ Quick Start

### Prerequisites

- Azure subscription with appropriate permissions
- Azure DevOps organization
- Azure CLI installed and configured
- kubectl installed
- Terraform installed (for infrastructure management)

### 1. Infrastructure Deployment

```bash
# Navigate to Terraform directory
cd automation/iac/app_svc/terraform

# Initialize Terraform
terraform init

# Deploy shared infrastructure
terraform apply -var-file=terraform_values/shared.tfvars
```

### 2. Application Deployment

#### Test Environment
```bash
# Connect to AKS cluster
az aks get-credentials --resource-group rg-resume-shared --name aks-resume-shared

# Deploy to test namespace
kubectl apply -f automation/k8s/manifests/namespace.yaml
kubectl apply -f automation/k8s/manifests/config_map/test.yaml
# ... (see CI/CD pipeline for complete deployment)
```

#### Production Environment
```bash
# Deploy to prod namespace
kubectl apply -f automation/k8s/manifests/config_map/prod.yaml
# ... (see CI/CD pipeline for complete deployment)
```

## 🔧 Configuration Management

### Environment Variables

| Environment | Spring Profile | Log Level | Purpose |
|-------------|---------------|-----------|---------|
| **Test** | `test` | `DEBUG` | Development and testing |
| **Production** | `prod` | `INFO` | Live production workloads |

### Resource Specifications

| Component | Test Namespace | Prod Namespace |
|-----------|---------------|----------------|
| **Replicas** | 1 | 1 |
| **CPU Request** | ~0.5 cores | ~0.5 cores |
| **Memory Request** | ~256Mi | ~256Mi |
| **External Access** | LoadBalancer IP | LoadBalancer IP |

## 🚀 CI/CD Pipeline

### Continuous Integration (CI)
```yaml
Triggers: Code changes to main branch
Jobs:
  1. Build & Test Java application
  2. Build & Push Docker image to ACR
     - Tags: $(Build.BuildId), latest
  3. Publish Terraform artifacts
  4. Publish Kubernetes manifests
```

### Continuous Deployment (CD)
```yaml
Test Environment:
  1. Connect to AKS cluster
  2. Create/update namespaces
  3. Configure ACR authentication
  4. Deploy application with build-specific image tag
  5. Verify deployment health

Production Environment:
  1. Manual approval gate
  2. Deploy same build to prod namespace
  3. Health checks and validation
```

## 🌐 Accessing the Application

### Service Endpoints

After deployment, get the external IP addresses:

```bash
# Test environment
kubectl get svc resume-service-lb -n test
# Access: http://<EXTERNAL-IP>:8080

# Production environment  
kubectl get svc resume-service-lb -n prod
# Access: http://<EXTERNAL-IP>:8080
```

### Available Endpoints

- **Health Check**: `GET /actuator/health`
- **Application Info**: `GET /`
- **Static Content**: `GET /welcome.txt`
- **Custom Endpoints**: As defined in Spring Boot controllers

## 🔍 Monitoring & Troubleshooting

### Common Commands

```bash
# Check pod status
kubectl get pods -n test
kubectl get pods -n prod

# View application logs
kubectl logs -l app=resume-service -n test
kubectl logs -l app=resume-service -n prod

# Check deployment status
kubectl rollout status deployment/resume-service-deployment -n test
kubectl rollout status deployment/resume-service-deployment -n prod

# Describe resources for debugging
kubectl describe pod -l app=resume-service -n test
kubectl describe svc resume-service-lb -n test
```

### Scaling Operations

```bash
# Scale test environment down (cost optimization)
kubectl scale deployment resume-service-deployment --replicas=0 -n test

# Scale back up
kubectl scale deployment resume-service-deployment --replicas=1 -n test
```

## 💰 Cost Optimization

### Shared Infrastructure Benefits
- **Single AKS cluster** for multiple environments
- **Namespace isolation** without infrastructure duplication
- **Resource sharing** across test and production workloads
- **Estimated cost**: ~$93/month vs $146/month for separate clusters

### Resource Management
- **Test environment** can be scaled down during non-work hours
- **Production environment** maintains high availability
- **Horizontal Pod Autoscaler** ready for future scaling needs

## 🔒 Security Considerations

### Authentication & Authorization
- **Azure service principal** for CI/CD authentication
- **ACR integration** with Kubernetes RBAC
- **Namespace isolation** for environment separation
- **Docker registry secrets** for private image access

### Best Practices Implemented
- **Least privilege access** for service accounts
- **Network policies** ready for implementation
- **Secret management** through Kubernetes secrets
- **Image scanning** capabilities through ACR

## 🚢 Deployment Strategies

### Current: Rolling Updates
- **Zero-downtime deployments** with rolling strategy
- **Build-specific image tags** prevent caching issues
- **Automatic rollback** on deployment failures

### Future: Blue-Green Deployments
- **Infrastructure ready** for blue-green implementation
- **Service selector switching** for instant traffic cutover
- **Argo Rollouts integration** for advanced deployment strategies

## 📊 Infrastructure Specifications

### Azure Resources

| Resource | Configuration | Purpose |
|----------|--------------|---------|
| **Resource Group** | `rg-resume-shared` | Logical container for all resources |
| **AKS Cluster** | `aks-resume-shared` | Kubernetes orchestration platform |
| **Node Pool** | 2 × Standard_B2s | Compute resources (4 vCPUs, 8GB RAM) |
| **ACR** | `amoshacr` | Private container registry |
| **Load Balancers** | 2 × Azure LB | External access for test and prod |

### Kubernetes Resources

| Resource Type | Test Namespace | Prod Namespace |
|---------------|----------------|----------------|
| **Deployment** | resume-service-deployment | resume-service-deployment |
| **Service** | resume-service-lb | resume-service-lb |
| **ConfigMap** | resume-service-config | resume-service-config |
| **Secret** | acr-auth | acr-auth |

## 🔄 Version Control & Branching

### Git Workflow
- **Main branch**: Production-ready code
- **Feature branches**: Development and testing
- **Pull requests**: Code review and quality gates
- **Tagged releases**: Correlated with build numbers

### Artifact Management
- **Docker images**: Tagged with build numbers and latest
- **Terraform state**: Managed through Azure backend
- **Kubernetes manifests**: Version controlled with template variables

## 📈 Future Enhancements

### Planned Improvements
- [ ] **Monitoring stack**: Prometheus + Grafana integration
- [ ] **Logging aggregation**: ELK stack or Azure Monitor
- [ ] **Service mesh**: Istio for advanced traffic management
- [ ] **GitOps workflow**: ArgoCD for declarative deployments
- [ ] **Multi-region deployment**: High availability across regions
- [ ] **Automated testing**: Integration and performance test suites

### Scalability Roadmap
- [ ] **Horizontal Pod Autoscaler**: CPU/memory-based scaling
- [ ] **Cluster Autoscaler**: Node-level scaling
- [ ] **Database integration**: Persistent data storage
- [ ] **Caching layer**: Redis for improved performance
- [ ] **CDN integration**: Global content delivery

## 🤝 Contributing

### Development Workflow
1. **Fork** the repository
2. **Create** feature branch from main
3. **Implement** changes with appropriate tests
4. **Submit** pull request for review
5. **Deploy** through CI/CD pipeline after approval

### Code Standards
- **Java**: Follow Spring Boot best practices
- **Docker**: Multi-stage builds for optimization
- **Kubernetes**: Resource limits and health checks
- **Terraform**: Module-based infrastructure design
