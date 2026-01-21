# Pre-Deployment Checklist

## Prerequisites ✓

### AWS Account
- [ ] AWS CLI installed and configured
- [ ] AWS credentials for account 114805761158
- [ ] IAM user: rdchandna exists
- [ ] Sufficient IAM permissions to create:
  - VPC, subnets, NAT Gateway
  - EKS cluster
  - IAM roles and policies
  - OIDC provider
  - EC2 instances

### Local Tools
- [ ] Terraform >= 1.0 installed
- [ ] kubectl installed
- [ ] Helm >= 3.0 installed
- [ ] Git (optional, for version control)

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

## Deployment Steps ✓

### 1. Navigate to Project
- [ ] `cd /Users/ramandeep_chandna/eks-terraform`

### 2. Review Configuration
- [ ] Check `terraform.tfvars` values
- [ ] Verify region: us-east-1
- [ ] Verify node count: 3
- [ ] Verify instance type: t3.micro
- [ ] Verify IAM user ARN

### 3. Initialize Terraform
- [ ] `terraform init`
- [ ] Verify providers downloaded

### 4. Plan Deployment
- [ ] `terraform plan -out=tfplan`
- [ ] Review planned changes
- [ ] Verify resource count (~50-60 resources)

### 5. Apply Infrastructure
- [ ] `terraform apply tfplan`
- [ ] Wait 15-20 minutes
- [ ] Verify no errors

### 6. Configure kubectl
- [ ] `aws eks update-kubeconfig --name my-eks-cluster --region us-east-1`
- [ ] `kubectl get nodes` (should show 3 nodes)

### 7. Deploy Applications
- [ ] Helm: `helm upgrade --install sample-app ./helm/sample-app`
- [ ] Kustomize: `kubectl apply -k ./kustomize/overlays/production`
- [ ] Wait for pods to be Running

### 8. Verify Deployment
- [ ] `kubectl get nodes` (3 nodes Ready)
- [ ] `kubectl get pods -A` (all pods Running)
- [ ] `kubectl get sa -n default` (s3-reader-sa exists)
- [ ] `kubectl get pods -n amazon-cloudwatch` (CloudWatch agent running)

## Post-Deployment Verification ✓

### Infrastructure
- [ ] VPC created with correct CIDR
- [ ] 3 public subnets created
- [ ] 3 private subnets created
- [ ] NAT Gateway operational
- [ ] Internet Gateway attached

### EKS Cluster
- [ ] Cluster status: ACTIVE
- [ ] Cluster version: 1.31
- [ ] Endpoint accessible
- [ ] OIDC issuer URL available

### Nodes
- [ ] 3 nodes in Ready state
- [ ] Instance type: t3.micro
- [ ] Nodes in different AZs
- [ ] Node IAM role attached

### IRSA
- [ ] OIDC provider registered in IAM
- [ ] S3 reader role created
- [ ] CloudWatch role created
- [ ] Service accounts have role annotations

### Applications
- [ ] sample-app: 3/3 pods Running
- [ ] aws-cli-app: 3/3 pods Running
- [ ] CloudWatch agent: Running
- [ ] All pods using correct service accounts

### IRSA Functionality
- [ ] Test command: `kubectl exec -it $(kubectl get pod -l app=aws-cli-app -o jsonpath='{.items[0].metadata.name}') -- aws sts get-caller-identity`
- [ ] Output shows assumed role (not node role)
- [ ] Test S3 access: `kubectl exec -it $(kubectl get pod -l app=aws-cli-app -o jsonpath='{.items[0].metadata.name}') -- aws s3 ls`
- [ ] Can list S3 buckets

### CloudWatch
- [ ] Navigate to CloudWatch Console
- [ ] Container Insights available
- [ ] Cluster metrics visible
- [ ] Pod metrics visible
- [ ] Logs streaming

### User Access
- [ ] User rdchandna in access entries
- [ ] Admin policy attached
- [ ] Can run kubectl commands
- [ ] Can view resources in AWS Console

## Troubleshooting Checklist ✓

### If Terraform Fails
- [ ] Check AWS credentials
- [ ] Verify IAM permissions
- [ ] Check region availability
- [ ] Review error messages
- [ ] Check Terraform state

### If Nodes Not Ready
- [ ] `kubectl describe nodes`
- [ ] Check node IAM role
- [ ] Verify VPC/subnet configuration
- [ ] Check security groups

### If Pods Pending
- [ ] `kubectl describe pod <pod-name>`
- [ ] Check node capacity
- [ ] Verify resource requests
- [ ] Check service account

### If IRSA Not Working
- [ ] Verify OIDC provider exists
- [ ] Check IAM role trust policy
- [ ] Verify service account annotation
- [ ] Check pod environment variables
- [ ] Review IAM role permissions

### If CloudWatch Not Collecting
- [ ] Check CloudWatch agent logs
- [ ] Verify IAM role permissions
- [ ] Check service account
- [ ] Verify cluster name in Helm values

## Cleanup Checklist ✓

### Before Destroying
- [ ] Backup any important data
- [ ] Export kubectl configs if needed
- [ ] Document any custom changes
- [ ] Notify team members

### Destroy Resources
- [ ] `cd /Users/ramandeep_chandna/eks-terraform`
- [ ] `terraform destroy`
- [ ] Confirm destruction
- [ ] Wait for completion (~10-15 minutes)
- [ ] Verify all resources deleted in AWS Console

### Post-Cleanup
- [ ] Check for orphaned resources
- [ ] Verify no unexpected charges
- [ ] Remove kubectl context: `kubectl config delete-context <context-name>`

## Documentation Checklist ✓

- [x] README.md (STAR format)
- [x] QUICKSTART.md
- [x] SUMMARY.md
- [x] This checklist
- [x] Terraform code
- [x] Helm chart
- [x] Kustomize configs
- [x] Deployment script

## Success Criteria ✓

- [ ] Cluster operational with 3 nodes
- [ ] All applications running
- [ ] IRSA working (pods can assume IAM roles)
- [ ] CloudWatch collecting metrics/logs
- [ ] User rdchandna has admin access
- [ ] No errors in any component
- [ ] Cost within expected range (~$122-127/month)
- [ ] All documentation complete

---

**Deployment Date:** _____________  
**Deployed By:** _____________  
**Cluster Name:** my-eks-cluster  
**Region:** us-east-1  
**Status:** [ ] Success [ ] Failed [ ] In Progress
