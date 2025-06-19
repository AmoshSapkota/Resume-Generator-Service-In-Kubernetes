# Resume Service Infrastructure

This Terraform configuration provisions Azure infrastructure for the Resume Service Spring Boot application using Azure Kubernetes Service (AKS).

## Architecture Overview

The infrastructure includes:

- **Resource Group** for organizing all Azure resources
- **Virtual Network** with dedicated subnet for AKS
- **Azure Kubernetes Service (AKS)** cluster with auto-scaling node pools
- **Azure Container Registry (ACR)** for storing Docker images
- **Log Analytics** workspace for monitoring and logging
- **RBAC Integration** between AKS and ACR for seamless image pulls
- **Network Security** with proper subnet configurations

## Prerequisites

1. **AWS CLI** configured with appropriate credentials
2. **Terraform** >= 1.0 installed
3. **Docker** for building and pushing images

## Quick Start

### 1. Initialize Terraform
```bash
cd infra/Terraform
terraform init
```

### 2. Configure Variables
```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your desired values
```

### 3. Plan the Infrastructure
```bash
terraform plan
```

### 4. Apply the Infrastructure
```bash
terraform apply
```

### 5. Build and Deploy Application
After infrastructure is created, use the output commands:

```bash
# Get ECR login command
terraform output ecr_login_command

# Build Docker image
cd ../../service
docker build -t resume-service .

# Tag and push to ECR
docker tag resume-service:latest $(terraform output -raw ecr_repository_url):latest
docker push $(terraform output -raw ecr_repository_url):latest

# Update ECS service
aws ecs update-service \
  --cluster $(terraform output -raw ecs_cluster_id) \
  --service $(terraform output -raw ecs_service_name) \
  --force-new-deployment
```

## Configuration Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `aws_region` | AWS region | `us-east-1` |
| `environment` | Environment name | `dev` |
| `project_name` | Project name | `resume-service` |
| `vpc_cidr` | VPC CIDR block | `10.0.0.0/16` |
| `az_count` | Number of availability zones | `2` |
| `container_port` | Application port | `8080` |
| `fargate_cpu` | CPU units (256 = 0.25 vCPU) | `256` |
| `fargate_memory` | Memory in MiB | `512` |
| `app_count` | Number of containers | `2` |

## Outputs

After applying, you'll get:

- **Application URL**: Load balancer DNS name
- **ECR Repository URL**: For pushing Docker images
- **ECS Cluster Info**: For deployments
- **Helper Commands**: Ready-to-use CLI commands

## Environment-Specific Deployments

### Development
```bash
terraform workspace new dev
terraform apply -var="environment=dev" -var="app_count=1"
```

### Staging
```bash
terraform workspace new staging
terraform apply -var="environment=staging" -var="app_count=2"
```

### Production
```bash
terraform workspace new prod
terraform apply -var="environment=prod" -var="app_count=3" -var="fargate_cpu=512" -var="fargate_memory=1024"
```

## Cost Optimization

For development/testing, you can reduce costs by:

```hcl
# In terraform.tfvars
fargate_cpu = 256
fargate_memory = 512
app_count = 1
az_count = 2
enable_nat_gateway = false  # Use only if private subnets don't need internet
```

## Security Features

- **Private subnets** for ECS tasks
- **Security groups** with minimal required access
- **NAT gateways** for secure outbound access
- **IAM roles** with least privilege
- **Container image scanning** enabled in ECR

## Monitoring and Logging

- **CloudWatch logs** for application logs
- **ECS Container Insights** for metrics
- **Load balancer access logs** (can be enabled)
- **Health checks** for application availability

## Cleanup

```bash
terraform destroy
```

## Troubleshooting

### Common Issues

1. **ECR Authentication**: Make sure AWS CLI is configured
2. **ECS Task Failures**: Check CloudWatch logs
3. **Load Balancer 503**: Verify health check endpoint
4. **Resource Limits**: Check AWS service quotas

### Useful Commands

```bash
# Check ECS service status
aws ecs describe-services --cluster resume-service-dev-cluster --services resume-service-dev-service

# View logs
aws logs tail /ecs/resume-service-dev --follow

# Check load balancer targets
aws elbv2 describe-target-health --target-group-arn $(terraform output -raw target_group_arn)
```

## CI/CD Integration

The outputs provide ready-to-use commands for CI/CD pipelines:

```yaml
# Example GitHub Actions workflow
- name: Build and Deploy
  run: |
    $(terraform output -raw ecr_login_command)
    $(terraform output -raw docker_build_command)
    $(terraform output -raw docker_push_command)
    $(terraform output -raw ecs_update_service_command)
```
