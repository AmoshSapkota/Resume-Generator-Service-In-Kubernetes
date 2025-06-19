# Resume Service Deployment Script for Windows PowerShell
# This script automates the deployment of the Resume Service to Azure

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("dev", "prod")]
    [string]$Environment = "dev",
    
    [Parameter(Mandatory=$false)]
    [switch]$BuildImage,
    
    [Parameter(Mandatory=$false)]
    [switch]$DeployInfra,
    
    [Parameter(Mandatory=$false)]
    [switch]$DeployApp,
    
    [Parameter(Mandatory=$false)]  
    [switch]$All
)

# Color functions for output
function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Blue
}

function Write-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

function Write-Error-Custom {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

# Check prerequisites
function Test-Prerequisites {
    Write-Info "Checking prerequisites..."
    
    $requiredCommands = @("az", "terraform", "kubectl", "docker")
    
    foreach ($cmd in $requiredCommands) {
        if (!(Get-Command $cmd -ErrorAction SilentlyContinue)) {
            Write-Error-Custom "$cmd is not installed or not in PATH"
            return $false
        }
    }
    
    # Check Azure login
    try {
        az account show | Out-Null
        if ($LASTEXITCODE -ne 0) {
            Write-Error-Custom "Not logged into Azure. Please run 'az login' first."
            return $false
        }
    }
    catch {
        Write-Error-Custom "Azure CLI not configured properly. Please run 'az login' first."
        return $false
    }
    
    Write-Success "All prerequisites met"
    return $true
}

# Deploy infrastructure with Terraform
function Deploy-Infrastructure {
    Write-Info "Deploying infrastructure with Terraform..."
    
    Push-Location "infra\Terraform"
    
    try {
        # Initialize Terraform
        terraform init
        if ($LASTEXITCODE -ne 0) { throw "Terraform init failed" }
        
        # Plan
        terraform plan -var="environment=$Environment"
        if ($LASTEXITCODE -ne 0) { throw "Terraform plan failed" }
        
        # Apply
        terraform apply -var="environment=$Environment" -auto-approve
        if ($LASTEXITCODE -ne 0) { throw "Terraform apply failed" }
        
        Write-Success "Infrastructure deployed successfully"
    }
    catch {
        Write-Error-Custom "Infrastructure deployment failed: $_"
        return $false
    }
    finally {
        Pop-Location
    }
    
    return $true
}

# Build and push Docker image
function Build-AndPushImage {
    Write-Info "Building and pushing Docker image..."
    
    try {
        # Get ACR details from Terraform
        Push-Location "infra\Terraform"
        $acrName = terraform output -raw acr_name
        $acrLoginServer = terraform output -raw acr_login_server
        Pop-Location
        
        if (!$acrName -or !$acrLoginServer) {
            throw "Could not get ACR details from Terraform. Make sure infrastructure is deployed."
        }
        
        # Login to ACR
        az acr login --name $acrName
        if ($LASTEXITCODE -ne 0) { throw "ACR login failed" }
        
        # Build image
        Push-Location "service"
        docker build -t resume-service .
        if ($LASTEXITCODE -ne 0) { throw "Docker build failed" }
        
        # Tag and push
        $imageTag = if ($Environment -eq "prod") { "v1.0.0" } else { "latest" }
        $fullImageName = "${acrLoginServer}/resume-service:${imageTag}"
        
        docker tag resume-service:latest $fullImageName
        if ($LASTEXITCODE -ne 0) { throw "Docker tag failed" }
        
        docker push $fullImageName
        if ($LASTEXITCODE -ne 0) { throw "Docker push failed" }
        
        Pop-Location
        Write-Success "Docker image built and pushed successfully"
        Write-Info "Image: $fullImageName"
    }
    catch {
        Write-Error-Custom "Image build/push failed: $_"
        return $false
    }
    
    return $true
}

# Deploy application to Kubernetes
function Deploy-Application {
    Write-Info "Deploying application to Kubernetes..."
    
    try {
        # Get AKS credentials
        Push-Location "infra\Terraform"
        $resourceGroup = terraform output -raw resource_group_name
        $clusterName = terraform output -raw cluster_name
        Pop-Location
        
        if (!$resourceGroup -or !$clusterName) {
            throw "Could not get AKS details from Terraform. Make sure infrastructure is deployed."
        }
        
        # Get AKS credentials
        az aks get-credentials --resource-group $resourceGroup --name $clusterName --overwrite-existing
        if ($LASTEXITCODE -ne 0) { throw "Failed to get AKS credentials" }
        
        # Deploy to Kubernetes
        Push-Location "k8s\$Environment"
        
        # Update image reference in kustomization.yaml
        $acrName = terraform -chdir="..\..\infra\Terraform" output -raw acr_name
        $newImageName = "${acrName}.azurecr.io/resume-service"
        
        # Apply manifests
        kubectl apply -k .
        if ($LASTEXITCODE -ne 0) { throw "Kubernetes deployment failed" }
        
        # Wait for deployment
        $deploymentName = if ($Environment -eq "prod") { "prod-resume-service" } else { "resume-service" }
        $namespace = if ($Environment -eq "prod") { "resume-service-prod" } else { "resume-service" }
        
        kubectl rollout status deployment/$deploymentName -n $namespace --timeout=300s
        if ($LASTEXITCODE -ne 0) { throw "Deployment rollout failed" }
        
        Pop-Location
        Write-Success "Application deployed successfully"
        
        # Show status
        kubectl get pods -n $namespace
        kubectl get services -n $namespace
    }
    catch {
        Write-Error-Custom "Application deployment failed: $_"
        return $false
    }
    
    return $true
}

# Main execution
function Main {
    Write-Info "Starting Resume Service deployment..."
    Write-Info "Environment: $Environment"
    
    if (!(Test-Prerequisites)) {
        exit 1
    }
    
    $success = $true
    
    if ($All -or $DeployInfra) {
        $success = $success -and (Deploy-Infrastructure)
    }
    
    if ($success -and ($All -or $BuildImage)) {
        $success = $success -and (Build-AndPushImage)
    }
    
    if ($success -and ($All -or $DeployApp)) {
        $success = $success -and (Deploy-Application)
    }
    
    if ($success) {
        Write-Success "Deployment completed successfully!"
        Write-Info "You can check your application status with:"
        Write-Info "kubectl get pods -n $(if ($Environment -eq 'prod') { 'resume-service-prod' } else { 'resume-service' })"
    } else {
        Write-Error-Custom "Deployment failed!"
        exit 1
    }
}

# Show usage if no parameters
if (!$All -and !$DeployInfra -and !$BuildImage -and !$DeployApp) {
    Write-Host @"
Resume Service Deployment Script

Usage:
    .\deploy.ps1 -All                          # Deploy everything (infrastructure + image + app)
    .\deploy.ps1 -DeployInfra                  # Deploy only infrastructure
    .\deploy.ps1 -BuildImage                   # Build and push Docker image only
    .\deploy.ps1 -DeployApp                    # Deploy app to Kubernetes only
    .\deploy.ps1 -Environment prod -All        # Deploy everything to production

Parameters:
    -Environment    Environment to deploy to (dev/prod) [default: dev]
    -All           Deploy infrastructure, build image, and deploy app
    -DeployInfra   Deploy infrastructure with Terraform
    -BuildImage    Build and push Docker image to ACR
    -DeployApp     Deploy application to Kubernetes
    
Examples:
    .\deploy.ps1 -All                          # Full deployment to dev
    .\deploy.ps1 -Environment prod -All        # Full deployment to prod
    .\deploy.ps1 -BuildImage -DeployApp        # Just build and deploy app
"@
} else {
    Main
}
