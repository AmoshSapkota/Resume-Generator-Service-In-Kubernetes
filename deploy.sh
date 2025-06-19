#!/bin/bash

# Resume Service Deployment Script
# This script helps deploy the application to different environments

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
ENVIRONMENT="dev"
ACTION="deploy"
BUILD_IMAGE=false
TERRAFORM_ACTION="apply"

# Function to print colored output
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to display usage
usage() {
    cat << EOF
Usage: $0 [OPTIONS]

OPTIONS:
    -e, --environment    Environment (dev/staging/prod) [default: dev]
    -a, --action        Action (deploy/destroy/plan) [default: deploy]
    -b, --build         Build Docker image before deployment
    -t, --terraform     Terraform action (apply/destroy/plan) [default: apply]
    -h, --help          Show this help message

EXAMPLES:
    $0 -e dev -a deploy -b                    # Deploy to dev with image build
    $0 -e staging -a plan                     # Plan staging deployment
    $0 -e prod -a deploy                      # Deploy to production
    $0 -e dev -a destroy                      # Destroy dev environment
EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -e|--environment)
            ENVIRONMENT="$2"
            shift 2
            ;;
        -a|--action)
            ACTION="$2"
            shift 2
            ;;
        -b|--build)
            BUILD_IMAGE=true
            shift
            ;;
        -t|--terraform)
            TERRAFORM_ACTION="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(dev|staging|prod)$ ]]; then
    print_error "Invalid environment: $ENVIRONMENT. Must be dev, staging, or prod."
    exit 1
fi

# Validate action
if [[ ! "$ACTION" =~ ^(deploy|destroy|plan)$ ]]; then
    print_error "Invalid action: $ACTION. Must be deploy, destroy, or plan."
    exit 1
fi

print_info "Starting deployment process..."
print_info "Environment: $ENVIRONMENT"
print_info "Action: $ACTION"
print_info "Build Image: $BUILD_IMAGE"

# Check prerequisites
check_prerequisites() {
    print_info "Checking prerequisites..."
    
    local required_commands=("terraform" "kubectl" "docker" "az")
    
    for cmd in "${required_commands[@]}"; do
        if ! command -v $cmd &> /dev/null; then
            print_error "$cmd is not installed or not in PATH"
            exit 1
        fi
    done
    
    # Check Azure credentials
    if ! az account show &> /dev/null; then
        print_error "Azure credentials not configured properly. Please run 'az login' first."
        exit 1
    fi
    
    print_success "All prerequisites met"
}

# Deploy infrastructure with Terraform
deploy_infrastructure() {
    print_info "Deploying infrastructure with Terraform..."
    
    cd infra/Terraform
    
    # Initialize Terraform
    terraform init
    
    # Select or create workspace
    terraform workspace select $ENVIRONMENT 2>/dev/null || terraform workspace new $ENVIRONMENT
    
    case $TERRAFORM_ACTION in
        "apply")
            terraform plan -var="environment=$ENVIRONMENT" -out=tfplan
            if [[ "$ACTION" == "deploy" ]]; then
                terraform apply tfplan
            fi
            ;;
        "destroy")
            terraform plan -destroy -var="environment=$ENVIRONMENT" -out=tfplan
            if [[ "$ACTION" == "destroy" ]]; then
                terraform apply tfplan
            fi
            ;;
        "plan")
            terraform plan -var="environment=$ENVIRONMENT"
            ;;
    esac
    
    cd ../..
}

# Build and push Docker image
build_and_push_image() {
    if [[ "$BUILD_IMAGE" == true ]]; then
        print_info "Building and pushing Docker image..."
        
        # Get ECR repository URL from Terraform output
        cd infra/Terraform
        ECR_REPO=$(terraform output -raw ecr_repository_url)
        ECR_LOGIN_CMD=$(terraform output -raw ecr_login_command)
        cd ../..
        
        # Login to ECR
        eval $ECR_LOGIN_CMD
        
        # Build Docker image
        cd service
        docker build -t resume-service .
        docker tag resume-service:latest $ECR_REPO:latest
        docker tag resume-service:latest $ECR_REPO:$ENVIRONMENT
        
        # Push to ECR
        docker push $ECR_REPO:latest
        docker push $ECR_REPO:$ENVIRONMENT
        
        cd ..
        
        print_success "Docker image built and pushed successfully"
    fi
}

# Configure kubectl
configure_kubectl() {
    print_info "Configuring kubectl..."
    
    cd infra/Terraform
    KUBECTL_CONFIG_CMD=$(terraform output -raw kubectl_config_command)
    cd ../..
    
    eval $KUBECTL_CONFIG_CMD
    
    # Verify connection
    kubectl get nodes
    
    print_success "kubectl configured successfully"
}

# Deploy Kubernetes manifests
deploy_kubernetes() {
    print_info "Deploying Kubernetes manifests..."
    
    case $ACTION in
        "deploy")
            kubectl apply -k k8s/$ENVIRONMENT
            
            # Wait for deployment to be ready
            kubectl wait --for=condition=available --timeout=300s deployment/resume-service -n resume-service 2>/dev/null || true
            
            print_success "Kubernetes manifests deployed successfully"
            ;;
        "destroy")
            kubectl delete -k k8s/$ENVIRONMENT --ignore-not-found=true
            print_success "Kubernetes resources deleted successfully"
            ;;
        "plan")
            kubectl diff -k k8s/$ENVIRONMENT || true
            ;;
    esac
}

# Get application status
get_status() {
    if [[ "$ACTION" == "deploy" ]]; then
        print_info "Getting application status..."
        
        echo ""
        print_info "Cluster Status:"
        kubectl get nodes
        
        echo ""
        print_info "Application Pods:"
        kubectl get pods -n resume-service -l app=resume-service
        
        echo ""
        print_info "Services:"
        kubectl get services -n resume-service
        
        echo ""
        print_info "Ingress:"
        kubectl get ingress -n resume-service
        
        # Get load balancer URL if available
        LB_HOSTNAME=$(kubectl get service nginx-ingress-ingress-nginx-controller -n ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "Not available")
        
        echo ""
        print_success "Deployment completed successfully!"
        print_info "Load Balancer Hostname: $LB_HOSTNAME"
        print_info "Application should be accessible via the load balancer"
    fi
}

# Main execution
main() {
    check_prerequisites
    
    if [[ "$ACTION" != "plan" ]]; then
        deploy_infrastructure
        
        if [[ "$TERRAFORM_ACTION" != "destroy" ]]; then
            build_and_push_image
            configure_kubectl
            deploy_kubernetes
            get_status
        fi
    else
        deploy_infrastructure
        deploy_kubernetes
    fi
}

# Run main function
main
