# EKS Deployment - Project Summary

## 📦 What's Included

Complete production-ready EKS deployment with:
- **Infrastructure as Code:** Terraform
- **Package Management:** Helm
- **Configuration Management:** Kustomize
- **Security:** IRSA (IAM Roles for Service Accounts)
- **Observability:** CloudWatch Container Insights
- **Documentation:** STAR format (Situation, Task, Action, Result)

## 📁 Project Structure

```
eks-terraform/
├── README.md              # Complete STAR documentation
├── QUICKSTART.md          # Quick start guide
├── main.tf                # Infrastructure (VPC, EKS, IRSA, CloudWatch)
├── providers.tf           # AWS, Kubernetes, Helm providers
├── variables.tf           # Input variables
├── outputs.tf             # Output values
├── terraform.tfvars       # Configuration values
├── deploy.sh              # Automated deployment script
├── helm/
│   └── sample-app/        # Helm chart for nginx app
│       ├── Chart.yaml
│       ├── values.yaml
│       └── templates/
│           └── deployment.yaml
└── kustomize/
    ├── base/              # Base AWS CLI app
    │   ├── deployment.yaml
    │   └── kustomization.yaml
    └── overlays/
        └── production/    # Production configuration
            └── kustomization.yaml
```

## 🚀 Quick Deploy

```bash
cd /Users/ramandeep_chandna/eks-terraform
./deploy.sh
```

## 🎯 Key Features

### 1. Infrastructure (Terraform)
- **VPC:** 10.0.0.0/16 with public/private subnets across 3 AZs
- **EKS Cluster:** Kubernetes 1.31 in us-east-1
- **Nodes:** 3x t3.micro instances (fixed capacity)
- **Networking:** NAT Gateway, Internet Gateway, route tables

### 2. Security (IRSA)
- **OIDC Provider:** Registered in IAM
- **S3 Reader Role:** Read-only S3 access for pods
- **CloudWatch Role:** Metrics/logs permissions
- **User Access:** rdchandna with cluster admin policy
- **No Static Credentials:** All pods use temporary credentials

### 3. Applications

**Helm Deployment (sample-app):**
- 3 nginx pods
- Service account: s3-reader-sa (IRSA enabled)
- ClusterIP service on port 80
- Resource requests: 100m CPU, 128Mi RAM

**Kustomize Deployment (aws-cli-app):**
- 3 AWS CLI pods
- Service account: s3-reader-sa (IRSA enabled)
- Base + production overlay pattern
- Resource requests: 50m CPU, 64Mi RAM

### 4. Observability (CloudWatch)
- **Container Insights:** Enabled
- **Metrics:** Cluster, node, pod, container level
- **Logs:** Application and system logs
- **Dashboard:** Available in CloudWatch console
- **Agent:** Deployed via Helm with IRSA

## ✅ Verification Steps

### Check Infrastructure
```bash
kubectl get nodes
# Expected: 3 nodes in Ready state
```

### Check Applications
```bash
kubectl get pods -A
# Expected: All pods Running
```

### Test IRSA
```bash
POD=$(kubectl get pod -l app=aws-cli-app -o jsonpath='{.items[0].metadata.name}')
kubectl exec -it $POD -- aws sts get-caller-identity
# Expected: Shows assumed role (not node role)
```

### View CloudWatch
```bash
kubectl get pods -n amazon-cloudwatch
# Expected: CloudWatch agent running
```

## 📊 Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                         AWS Account                          │
│  ┌───────────────────────────────────────────────────────┐  │
│  │                    VPC (10.0.0.0/16)                   │  │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐ │  │
│  │  │ Public Subnet│  │ Public Subnet│  │ Public Subnet│ │  │
│  │  │  us-east-1a  │  │  us-east-1b  │  │  us-east-1c  │ │  │
│  │  └──────┬───────┘  └──────────────┘  └──────────────┘ │  │
│  │         │                                               │  │
│  │    NAT Gateway                                          │  │
│  │         │                                               │  │
│  │  ┌──────┴───────┐  ┌──────────────┐  ┌──────────────┐ │  │
│  │  │Private Subnet│  │Private Subnet│  │Private Subnet│ │  │
│  │  │  us-east-1a  │  │  us-east-1b  │  │  us-east-1c  │ │  │
│  │  │              │  │              │  │              │ │  │
│  │  │  ┌────────┐  │  │  ┌────────┐  │  │  ┌────────┐  │ │  │
│  │  │  │ Node 1 │  │  │  │ Node 2 │  │  │  │ Node 3 │  │ │  │
│  │  │  │t3.micro│  │  │  │t3.micro│  │  │  │t3.micro│  │ │  │
│  │  │  └────────┘  │  │  └────────┘  │  │  └────────┘  │ │  │
│  │  └──────────────┘  └──────────────┘  └──────────────┘ │  │
│  └───────────────────────────────────────────────────────┘  │
│                                                              │
│  ┌───────────────────────────────────────────────────────┐  │
│  │                    EKS Control Plane                   │  │
│  │                   (Managed by AWS)                     │  │
│  └───────────────────────────────────────────────────────┘  │
│                                                              │
│  ┌───────────────────────────────────────────────────────┐  │
│  │                      IAM / OIDC                        │  │
│  │  ┌─────────────────┐  ┌─────────────────┐            │  │
│  │  │ OIDC Provider   │  │  IAM Roles      │            │  │
│  │  │ (IRSA)          │  │  - S3 Reader    │            │  │
│  │  │                 │  │  - CloudWatch   │            │  │
│  │  └─────────────────┘  └─────────────────┘            │  │
│  └───────────────────────────────────────────────────────┘  │
│                                                              │
│  ┌───────────────────────────────────────────────────────┐  │
│  │                    CloudWatch                          │  │
│  │  - Container Insights                                  │  │
│  │  - Metrics & Logs                                      │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

## 💰 Cost Breakdown

| Component | Monthly Cost |
|-----------|--------------|
| EKS Control Plane | $73 |
| 3x t3.micro nodes | $9 |
| EBS volumes (3x 20GB) | $3 |
| NAT Gateway | $32 |
| Data transfer | $5-10 |
| **Total** | **$122-127** |

## 🔧 Management Commands

### Update Applications
```bash
# Helm
helm upgrade sample-app ./helm/sample-app --values custom-values.yaml

# Kustomize
kubectl apply -k ./kustomize/overlays/production
```

### Scale Applications
```bash
kubectl scale deployment sample-app --replicas=5
kubectl scale deployment aws-cli-app --replicas=5
```

### View Logs
```bash
kubectl logs -l app=sample-app
kubectl logs -l app=aws-cli-app
kubectl logs -n amazon-cloudwatch -l app.kubernetes.io/name=aws-cloudwatch-metrics
```

### Destroy Cluster
```bash
terraform destroy
```

## 📚 Documentation

- **README.md** - Complete STAR documentation (Situation, Task, Action, Result)
- **QUICKSTART.md** - Quick start guide
- **This file** - Project summary

## 🎓 Learning Outcomes

After deploying this project, you'll understand:
- ✅ EKS cluster architecture
- ✅ IRSA (IAM Roles for Service Accounts)
- ✅ Terraform for infrastructure automation
- ✅ Helm for application packaging
- ✅ Kustomize for configuration management
- ✅ CloudWatch Container Insights
- ✅ Kubernetes security best practices

## 🔗 References

- [EKS Documentation](https://docs.aws.amazon.com/eks/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Helm Documentation](https://helm.sh/docs/)
- [Kustomize Documentation](https://kustomize.io/)
- [IRSA Guide](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html)
- [CloudWatch Container Insights](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/ContainerInsights.html)

## 🤝 Support

For issues or questions:
1. Check `README.md` for detailed troubleshooting
2. Review Terraform/Kubernetes logs
3. Verify AWS permissions

---

**Created:** January 21, 2026  
**Status:** Ready to Deploy  
**Deployment Time:** ~15-20 minutes
