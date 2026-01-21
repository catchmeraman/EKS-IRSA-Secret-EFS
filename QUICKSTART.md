# EKS Deployment - Quick Start Guide

## Prerequisites
- AWS CLI configured
- Terraform >= 1.0
- kubectl installed
- Helm >= 3.0

## Deploy in 3 Steps

### 1. Navigate to project
```bash
cd /Users/ramandeep_chandna/eks-terraform
```

### 2. Run deployment script
```bash
./deploy.sh
```

This will:
- Initialize Terraform
- Create VPC, EKS cluster, nodes
- Configure OIDC provider
- Deploy applications (Helm + Kustomize)
- Install CloudWatch observability
- Configure kubectl

**Time:** ~15-20 minutes

### 3. Verify deployment
```bash
# Check nodes
kubectl get nodes

# Check pods
kubectl get pods -A

# Test IRSA
POD=$(kubectl get pod -l app=aws-cli-app -o jsonpath='{.items[0].metadata.name}')
kubectl exec -it $POD -- aws sts get-caller-identity
```

## What Gets Deployed

### Infrastructure
- ✅ VPC with public/private subnets
- ✅ EKS cluster (Kubernetes 1.31)
- ✅ 3 t3.micro worker nodes
- ✅ OIDC provider for IRSA

### Security
- ✅ IAM role for S3 access (IRSA)
- ✅ IAM role for CloudWatch (IRSA)
- ✅ User access for rdchandna

### Applications
- ✅ sample-app (3 nginx pods via Helm)
- ✅ aws-cli-app (3 AWS CLI pods via Kustomize)
- ✅ CloudWatch agent (observability)

### Observability
- ✅ CloudWatch Container Insights
- ✅ Cluster, node, pod metrics
- ✅ Application logs

## Access CloudWatch

1. Go to AWS Console → CloudWatch
2. Click "Container Insights"
3. Select cluster: my-eks-cluster
4. View metrics and logs

## Clean Up

```bash
cd /Users/ramandeep_chandna/eks-terraform
terraform destroy
```

## Cost

~$122-127/month:
- EKS control plane: $73
- 3x t3.micro nodes: $9
- NAT Gateway: $32
- Other: $8-13

## Troubleshooting

**Nodes not ready:**
```bash
kubectl describe nodes
```

**Pods pending:**
```bash
kubectl describe pod <pod-name>
```

**IRSA not working:**
```bash
kubectl get sa s3-reader-sa -o yaml
kubectl describe pod <pod-name> | grep AWS
```

**CloudWatch not collecting:**
```bash
kubectl logs -n amazon-cloudwatch -l app.kubernetes.io/name=aws-cloudwatch-metrics
```

## Documentation

See `README.md` for complete STAR documentation with detailed explanations.
