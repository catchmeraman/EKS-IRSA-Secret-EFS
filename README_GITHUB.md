# EKS IRSA Secret EFS

Complete production-ready Amazon EKS deployment with IRSA (IAM Roles for Service Accounts), AWS Secrets Manager, EFS (Elastic File System), EBS (Elastic Block Store), and CloudWatch observability.

[![Terraform](https://img.shields.io/badge/Terraform-1.0+-purple.svg)](https://www.terraform.io/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-1.31-blue.svg)](https://kubernetes.io/)
[![AWS](https://img.shields.io/badge/AWS-EKS-orange.svg)](https://aws.amazon.com/eks/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Detailed Setup](#detailed-setup)
- [Components Explained](#components-explained)
- [Usage Examples](#usage-examples)
- [Verification](#verification)
- [Troubleshooting](#troubleshooting)
- [Cost Estimation](#cost-estimation)
- [Best Practices](#best-practices)
- [Documentation](#documentation)
- [Contributing](#contributing)

## 🎯 Overview

This project provides a complete Infrastructure as Code (IaC) solution for deploying a production-ready Amazon EKS cluster with advanced features including:

- **IRSA (IAM Roles for Service Accounts)**: Secure pod-level AWS permissions without static credentials
- **AWS Secrets Manager**: Centralized secret management with automatic rotation support
- **EFS (Elastic File System)**: Shared storage across multiple pods
- **EBS (Elastic Block Store)**: Persistent block storage for stateful applications
- **CloudWatch Container Insights**: Comprehensive observability and monitoring
- **Helm & Kustomize**: Modern application deployment patterns

### Why This Project?

- ✅ **Production-Ready**: Battle-tested configurations and best practices
- ✅ **Security-First**: IRSA, encrypted storage, no hardcoded credentials
- ✅ **Fully Automated**: One-command deployment with Terraform
- ✅ **Well-Documented**: Comprehensive guides from basic to advanced
- ✅ **Cost-Optimized**: Right-sized resources with cost breakdown

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         AWS Account                              │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                    VPC (10.0.0.0/16)                        │ │
│  │                                                              │ │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │ │
│  │  │Public Subnet │  │Public Subnet │  │Public Subnet │     │ │
│  │  │  us-east-1a  │  │  us-east-1b  │  │  us-east-1c  │     │ │
│  │  └──────┬───────┘  └──────────────┘  └──────────────┘     │ │
│  │         │                                                    │ │
│  │    NAT Gateway                                               │ │
│  │         │                                                    │ │
│  │  ┌──────┴───────┐  ┌──────────────┐  ┌──────────────┐     │ │
│  │  │Private Subnet│  │Private Subnet│  │Private Subnet│     │ │
│  │  │  us-east-1a  │  │  us-east-1b  │  │  us-east-1c  │     │ │
│  │  │              │  │              │  │              │     │ │
│  │  │  ┌────────┐  │  │  ┌────────┐  │  │  ┌────────┐  │     │ │
│  │  │  │ Node 1 │  │  │  │ Node 2 │  │  │  │ Node 3 │  │     │ │
│  │  │  │t3.micro│  │  │  │t3.micro│  │  │  │t3.micro│  │     │ │
│  │  │  └────────┘  │  │  └────────┘  │  │  └────────┘  │     │ │
│  │  └──────────────┘  └──────────────┘  └──────────────┘     │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                    EKS Control Plane                        │ │
│  │                   (Managed by AWS)                          │ │
│  │                                                              │ │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │ │
│  │  │   OIDC       │  │  IAM Roles   │  │   Access     │     │ │
│  │  │  Provider    │  │   (IRSA)     │  │   Entries    │     │ │
│  │  └──────────────┘  └──────────────┘  └──────────────┘     │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                    Storage & Secrets                        │ │
│  │                                                              │ │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │ │
│  │  │   Secrets    │  │     EFS      │  │     EBS      │     │ │
│  │  │   Manager    │  │  (Shared)    │  │ (Persistent) │     │ │
│  │  └──────────────┘  └──────────────┘  └──────────────┘     │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                    CloudWatch                               │ │
│  │              Container Insights & Logs                      │ │
│  └────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

## ✨ Features

### Infrastructure
- ✅ **EKS Cluster**: Kubernetes 1.31 with managed control plane
- ✅ **VPC**: Custom VPC with public/private subnets across 3 AZs
- ✅ **Worker Nodes**: 3x t3.micro instances (customizable)
- ✅ **Networking**: NAT Gateway, Internet Gateway, route tables

### Security
- ✅ **IRSA**: IAM Roles for Service Accounts (no static credentials)
- ✅ **OIDC Provider**: Secure authentication for pods
- ✅ **Encryption**: EFS and EBS volumes encrypted at rest
- ✅ **IAM Access**: User-based cluster access with policies

### Storage
- ✅ **EFS**: Shared file system (ReadWriteMany)
- ✅ **EBS**: Persistent block storage (ReadWriteOnce)
- ✅ **CSI Drivers**: Kubernetes integration for both storage types
- ✅ **Dynamic Provisioning**: Automatic volume creation

### Secrets Management
- ✅ **AWS Secrets Manager**: Centralized secret storage
- ✅ **Secrets Store CSI Driver**: Mount secrets as files
- ✅ **Auto-Sync**: Secrets synced to Kubernetes
- ✅ **IRSA Integration**: Secure access without credentials

### Observability
- ✅ **CloudWatch Container Insights**: Cluster, node, pod metrics
- ✅ **Log Aggregation**: Application and system logs
- ✅ **Dashboards**: Pre-built CloudWatch dashboards

### Deployment
- ✅ **Terraform**: Infrastructure as Code
- ✅ **Helm**: Package management for Kubernetes
- ✅ **Kustomize**: Configuration management
- ✅ **Automated Script**: One-command deployment

## 📦 Prerequisites

### Required Tools
- **AWS CLI** (v2.x): [Install Guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- **Terraform** (≥ 1.0): [Install Guide](https://developer.hashicorp.com/terraform/downloads)
- **kubectl** (≥ 1.28): [Install Guide](https://kubernetes.io/docs/tasks/tools/)
- **Helm** (≥ 3.0): [Install Guide](https://helm.sh/docs/intro/install/)

### AWS Requirements
- AWS Account with appropriate permissions
- IAM user with access keys configured
- Permissions to create:
  - VPC, subnets, NAT Gateway
  - EKS cluster
  - IAM roles and policies
  - OIDC provider
  - EC2 instances
  - EFS file system
  - Secrets Manager secrets

### Verify Prerequisites
```bash
# Check AWS CLI
aws --version
aws sts get-caller-identity

# Check Terraform
terraform version

# Check kubectl
kubectl version --client

# Check Helm
helm version
```

## 🚀 Quick Start

### 1. Clone Repository
```bash
git clone https://github.com/YOUR_USERNAME/EKS-IRSA-Secret-EFS.git
cd EKS-IRSA-Secret-EFS
```

### 2. Configure Variables
Edit `terraform.tfvars`:
```hcl
cluster_name    = "my-eks-cluster"
region          = "us-east-1"
node_count      = 3
instance_type   = "t3.micro"
iam_user_arn    = "arn:aws:iam::YOUR_ACCOUNT_ID:user/YOUR_USERNAME"
```

### 3. Deploy
```bash
./deploy.sh
```

**That's it!** The script will:
- Initialize Terraform
- Create all infrastructure
- Configure kubectl
- Deploy applications
- Install observability stack

**Time:** ~15-20 minutes

### 4. Verify
```bash
# Check nodes
kubectl get nodes

# Check pods
kubectl get pods -A

# Test IRSA
POD=$(kubectl get pod -l app=aws-cli-app -o jsonpath='{.items[0].metadata.name}')
kubectl exec -it $POD -- aws sts get-caller-identity
```

## 📚 Detailed Setup

### Step 1: Initialize Terraform
```bash
cd eks-terraform
terraform init
```

This downloads required providers:
- AWS Provider (~200MB)
- Kubernetes Provider
- Helm Provider

### Step 2: Review Plan
```bash
terraform plan -out=tfplan
```

Review the resources to be created (~60 resources):
- VPC and networking (10 resources)
- EKS cluster (15 resources)
- IAM roles and policies (10 resources)
- Storage (EFS, EBS) (8 resources)
- CSI drivers (5 resources)
- Applications (12 resources)

### Step 3: Apply Infrastructure
```bash
terraform apply tfplan
```

**Timeline:**
- VPC creation: 2-3 minutes
- EKS control plane: 10-12 minutes
- Worker nodes: 3-5 minutes
- CSI drivers & apps: 2-3 minutes

### Step 4: Configure kubectl
```bash
aws eks update-kubeconfig --name my-eks-cluster --region us-east-1
```

This updates `~/.kube/config` with cluster credentials.

### Step 5: Wait for Nodes
```bash
kubectl wait --for=condition=Ready nodes --all --timeout=300s
```

### Step 6: Deploy Applications
```bash
# Helm deployment
helm upgrade --install sample-app ./helm/sample-app

# Kustomize deployment
kubectl apply -k ./kustomize/overlays/production
```

### Step 7: Verify Deployment
```bash
kubectl get nodes
kubectl get pods -A
kubectl get pvc
kubectl get secretproviderclass
```

## 🔧 Components Explained

### 1. IRSA (IAM Roles for Service Accounts)

**What is IRSA?**
IRSA allows Kubernetes pods to assume IAM roles without using static AWS credentials.

**How it works:**
```
Pod → Service Account → OIDC Token → AWS STS → Temporary Credentials
```

**Benefits:**
- ✅ No static credentials in pods
- ✅ Automatic credential rotation
- ✅ Fine-grained permissions per pod
- ✅ Full CloudTrail audit trail

**Example:**
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: app-sa
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::ACCOUNT:role/app-role
```

Pods using this service account automatically get temporary AWS credentials.

### 2. AWS Secrets Manager

**What is Secrets Manager?**
Centralized service for storing and managing secrets (passwords, API keys, certificates).

**Integration:**
- **Secrets Store CSI Driver**: Mounts secrets as files in pods
- **AWS Provider**: Connects to Secrets Manager
- **Auto-Sync**: Creates Kubernetes secrets automatically

**Secret Flow:**
```
Secrets Manager → CSI Driver → Pod (/mnt/secrets) → Kubernetes Secret → Env Vars
```

**Usage:**
```bash
# Access as files
cat /mnt/secrets/username

# Access as environment variables
echo $DB_USERNAME
```

### 3. EFS (Elastic File System)

**What is EFS?**
Fully managed, elastic, shared file system for AWS.

**Characteristics:**
- **Access Mode**: ReadWriteMany (multiple pods simultaneously)
- **Use Cases**: Shared files, logs, media, configuration
- **Performance**: Scales with size
- **Availability**: Multi-AZ by default

**Example:**
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: efs-pvc
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: efs-sc
  resources:
    requests:
      storage: 5Gi
```

### 4. EBS (Elastic Block Store)

**What is EBS?**
Block-level storage volumes for EC2 instances.

**Characteristics:**
- **Access Mode**: ReadWriteOnce (single pod at a time)
- **Use Cases**: Databases, stateful applications
- **Performance**: Consistent IOPS (gp3)
- **Persistence**: Data survives pod restarts

**Example:**
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: ebs-pvc
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: ebs-gp3
  resources:
    requests:
      storage: 10Gi
```

### 5. CloudWatch Container Insights

**What is Container Insights?**
Monitoring solution for containerized applications.

**Metrics Collected:**
- Cluster: CPU, memory, network, disk
- Node: Resource utilization per node
- Pod: Resource usage per pod
- Container: Individual container metrics

**Access:**
AWS Console → CloudWatch → Container Insights → Select cluster

## 💡 Usage Examples

### Example 1: Application with Secrets

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  template:
    spec:
      serviceAccountName: app-sa  # IRSA enabled
      containers:
      - name: app
        image: my-app:latest
        env:
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: app-secret-k8s
              key: password
        volumeMounts:
        - name: secrets
          mountPath: /mnt/secrets
          readOnly: true
      volumes:
      - name: secrets
        csi:
          driver: secrets-store.csi.k8s.io
          readOnly: true
          volumeAttributes:
            secretProviderClass: app-secrets
```

### Example 2: Shared Storage (EFS)

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
spec:
  replicas: 3
  template:
    spec:
      containers:
      - name: nginx
        image: nginx
        volumeMounts:
        - name: shared-content
          mountPath: /usr/share/nginx/html
      volumes:
      - name: shared-content
        persistentVolumeClaim:
          claimName: efs-pvc
```

All 3 replicas share the same content directory.

### Example 3: Persistent Database (EBS)

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres
spec:
  serviceName: postgres
  replicas: 1
  template:
    spec:
      containers:
      - name: postgres
        image: postgres:15
        volumeMounts:
        - name: data
          mountPath: /var/lib/postgresql/data
  volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      accessModes: ["ReadWriteOnce"]
      storageClassName: ebs-gp3
      resources:
        requests:
          storage: 20Gi
```

Data persists even if pod is deleted.

## ✅ Verification

### Check Infrastructure
```bash
# Nodes
kubectl get nodes
# Expected: 3 nodes in Ready state

# Pods
kubectl get pods -A
# Expected: All pods Running

# Storage
kubectl get pvc
# Expected: PVCs Bound

# Secrets
kubectl get secretproviderclass
kubectl get secret app-secret-k8s
```

### Test IRSA
```bash
POD=$(kubectl get pod -l app=aws-cli-app -o jsonpath='{.items[0].metadata.name}')

# Check assumed role
kubectl exec -it $POD -- aws sts get-caller-identity
# Should show: assumed-role/my-eks-cluster-app-role

# Test S3 access
kubectl exec -it $POD -- aws s3 ls

# Test Secrets Manager
kubectl exec -it $POD -- aws secretsmanager get-secret-value --secret-id my-eks-cluster-app-secret
```

### Test EFS (Shared Storage)
```bash
# Write from pod 1
POD1=$(kubectl get pod -l app=sample-app -o jsonpath='{.items[0].metadata.name}')
kubectl exec $POD1 -- sh -c "echo 'Hello EFS' > /mnt/efs/test.txt"

# Read from pod 2
POD2=$(kubectl get pod -l app=sample-app -o jsonpath='{.items[1].metadata.name}')
kubectl exec $POD2 -- cat /mnt/efs/test.txt
# Output: Hello EFS
```

### Test EBS (Persistent Storage)
```bash
POD=$(kubectl get pod -l app=aws-cli-app -o jsonpath='{.items[0].metadata.name}')

# Write data
kubectl exec $POD -- sh -c "echo 'Persistent' > /data/test.txt"

# Delete pod
kubectl delete pod $POD

# Verify data persists
sleep 10
POD_NEW=$(kubectl get pod -l app=aws-cli-app -o jsonpath='{.items[0].metadata.name}')
kubectl exec $POD_NEW -- cat /data/test.txt
# Output: Persistent
```

### Test Secrets
```bash
POD=$(kubectl get pod -l app=sample-app -o jsonpath='{.items[0].metadata.name}')

# Check mounted secrets
kubectl exec $POD -- ls /mnt/secrets
# Output: username password api_key

# Check environment variables
kubectl exec $POD -- env | grep DB_
# Output: DB_USERNAME=admin DB_PASSWORD=changeme123
```

### Check CloudWatch
```bash
# CloudWatch agent
kubectl get pods -n amazon-cloudwatch

# View logs
kubectl logs -n amazon-cloudwatch -l app.kubernetes.io/name=aws-cloudwatch-metrics
```

**In AWS Console:**
CloudWatch → Container Insights → Select cluster → View metrics

## 🔍 Troubleshooting

### Issue: Nodes Not Ready

**Check:**
```bash
kubectl describe nodes
kubectl get events --sort-by='.lastTimestamp'
```

**Common Causes:**
- IAM role not attached to nodes
- Security group blocking traffic
- Insufficient capacity in AZ

### Issue: Pods Pending

**Check:**
```bash
kubectl describe pod <pod-name>
```

**Common Causes:**
- Insufficient node resources
- PVC not bound
- Image pull errors

### Issue: IRSA Not Working

**Check:**
```bash
# Service account annotation
kubectl get sa app-sa -o yaml

# Pod environment variables
kubectl describe pod <pod-name> | grep AWS

# IAM role trust policy
aws iam get-role --role-name my-eks-cluster-app-role
```

**Common Causes:**
- Service account missing role annotation
- IAM role trust policy incorrect
- OIDC provider not registered

### Issue: EFS Mount Failures

**Check:**
```bash
# Mount targets
aws efs describe-mount-targets --file-system-id <fs-id>

# Security group
aws ec2 describe-security-groups --group-ids <sg-id>

# CSI driver logs
kubectl logs -n kube-system -l app.kubernetes.io/name=aws-efs-csi-driver
```

**Common Causes:**
- Security group not allowing NFS (port 2049)
- Mount target not in correct subnet
- CSI driver not running

### Issue: Secrets Not Mounting

**Check:**
```bash
# CSI driver
kubectl get pods -n kube-system -l app=secrets-store-csi-driver

# Provider
kubectl get pods -n kube-system -l app=csi-secrets-store-provider-aws

# IAM permissions
aws iam get-role-policy --role-name my-eks-cluster-app-role --policy-name app-access
```

**Common Causes:**
- CSI driver not installed
- IAM role missing secretsmanager permissions
- Secret name incorrect in SecretProviderClass

## 💰 Cost Estimation

### Monthly Costs (us-east-1)

| Component | Cost | Details |
|-----------|------|---------|
| **EKS Control Plane** | $73 | $0.10/hour |
| **EC2 (3x t3.micro)** | $9 | $0.0104/hour × 3 |
| **EBS (3x 20GB gp3)** | $2.40 | $0.08/GB/month × 60GB |
| **EFS** | Variable | $0.30/GB/month (usage-based) |
| **NAT Gateway** | $32 | $0.045/hour |
| **Data Transfer** | $5-10 | Variable |
| **Secrets Manager** | $0.40 | $0.40/secret/month |
| **CloudWatch** | $5-10 | Logs and metrics |
| **Total** | **~$127-137/month** | |

### Cost Optimization Tips

1. **Use Spot Instances**: Save up to 90% on compute
2. **Right-Size Nodes**: Use larger instances with fewer nodes
3. **EFS Lifecycle**: Move infrequent data to IA storage class
4. **VPC Endpoints**: Reduce NAT Gateway usage
5. **Reserved Instances**: Save 30-50% with 1-year commitment

## 🎯 Best Practices

### Security
- ✅ Always use IRSA (never static credentials)
- ✅ Enable encryption for EFS and EBS
- ✅ Rotate secrets regularly
- ✅ Use least privilege IAM policies
- ✅ Enable CloudTrail for audit logs

### Storage
- ✅ Use EFS for shared files
- ✅ Use EBS for databases
- ✅ Enable volume expansion
- ✅ Regular backups (Velero)
- ✅ Monitor storage usage

### Operations
- ✅ Use Terraform for infrastructure
- ✅ Version control all code
- ✅ Test in dev before production
- ✅ Monitor with CloudWatch
- ✅ Set up alerts for critical metrics

### Cost
- ✅ Right-size resources
- ✅ Use Spot instances where possible
- ✅ Delete unused volumes
- ✅ Monitor costs with AWS Cost Explorer
- ✅ Set up billing alerts

## 📖 Documentation

- **[README.md](README.md)** - Complete STAR documentation
- **[QUICKSTART.md](QUICKSTART.md)** - Quick start guide
- **[STORAGE_SECRETS_GUIDE.md](STORAGE_SECRETS_GUIDE.md)** - Storage & secrets deep dive
- **[STORAGE_QUICKREF.md](STORAGE_QUICKREF.md)** - Quick reference
- **[CHECKLIST.md](CHECKLIST.md)** - Deployment checklist
- **[SUMMARY.md](SUMMARY.md)** - Project summary

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- AWS EKS Team for excellent documentation
- Terraform AWS Provider maintainers
- Kubernetes community
- CSI driver developers

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/YOUR_USERNAME/EKS-IRSA-Secret-EFS/issues)
- **Discussions**: [GitHub Discussions](https://github.com/YOUR_USERNAME/EKS-IRSA-Secret-EFS/discussions)
- **AWS Documentation**: [EKS User Guide](https://docs.aws.amazon.com/eks/)

---

**Created**: January 2026  
**Status**: Production Ready  
**Deployment Time**: ~15-20 minutes  
**Cost**: ~$127-137/month
