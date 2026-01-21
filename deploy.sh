#!/bin/bash
set -e

echo "=== EKS Cluster Deployment Script ==="
echo ""

# Step 1: Initialize Terraform
echo "Step 1: Initializing Terraform..."
terraform init

# Step 2: Plan
echo ""
echo "Step 2: Planning Terraform deployment..."
terraform plan -out=tfplan

# Step 3: Apply
echo ""
echo "Step 3: Applying Terraform configuration..."
terraform apply tfplan

# Step 4: Configure kubectl
echo ""
echo "Step 4: Configuring kubectl..."
CLUSTER_NAME=$(terraform output -raw cluster_name)
REGION=$(grep region terraform.tfvars | cut -d'"' -f2)
aws eks update-kubeconfig --name $CLUSTER_NAME --region $REGION

# Step 5: Wait for nodes
echo ""
echo "Step 5: Waiting for nodes to be ready..."
kubectl wait --for=condition=Ready nodes --all --timeout=300s

# Step 6: Deploy Helm chart
echo ""
echo "Step 6: Deploying sample application via Helm..."
helm upgrade --install sample-app ./helm/sample-app --namespace default --create-namespace

# Step 7: Deploy Kustomize app
echo ""
echo "Step 7: Deploying AWS CLI app via Kustomize..."
kubectl apply -k ./kustomize/overlays/production

# Step 8: Verify deployments
echo ""
echo "Step 8: Verifying deployments..."
echo ""
echo "Nodes:"
kubectl get nodes
echo ""
echo "Pods:"
kubectl get pods -A
echo ""
echo "Service Accounts:"
kubectl get sa -n default
echo ""
echo "CloudWatch Observability:"
kubectl get pods -n amazon-cloudwatch

echo ""
echo "=== Deployment Complete ==="
echo ""
echo "Cluster Name: $CLUSTER_NAME"
echo "Region: $REGION"
echo ""
echo "To test IRSA:"
echo "kubectl exec -it \$(kubectl get pod -l app=aws-cli-app -o jsonpath='{.items[0].metadata.name}') -- aws sts get-caller-identity"
