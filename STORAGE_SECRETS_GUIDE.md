# Storage and Secrets Integration Guide

## Overview

This guide explains how to use **AWS Secrets Manager**, **EFS (Elastic File System)**, and **EBS (Elastic Block Store)** volumes in your EKS applications.

## What Was Added

### 1. AWS Secrets Manager Integration
- **Secrets Store CSI Driver**: Mounts secrets as files
- **AWS Secrets Manager Provider**: Connects to AWS Secrets Manager
- **IRSA**: Pods access secrets without static credentials
- **Kubernetes Secrets**: Auto-synced from Secrets Manager

### 2. EFS (Shared Storage)
- **EFS File System**: Encrypted, shared across all pods
- **EFS CSI Driver**: Kubernetes integration
- **Storage Class**: `efs-sc` for dynamic provisioning
- **Mount Targets**: One per availability zone

### 3. EBS (Block Storage)
- **EBS CSI Driver**: Kubernetes integration
- **Storage Class**: `ebs-gp3` (default, encrypted)
- **Dynamic Provisioning**: Automatic volume creation
- **Volume Expansion**: Resize without downtime

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                         Pod                                  │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  Container                                             │ │
│  │  ┌──────────────┐  ┌──────────────┐  ┌─────────────┐ │ │
│  │  │ /mnt/secrets │  │  /mnt/efs    │  │  /mnt/ebs   │ │ │
│  │  │  (read-only) │  │ (ReadWrite   │  │ (ReadWrite  │ │ │
│  │  │              │  │  Many)       │  │  Once)      │ │ │
│  │  └──────┬───────┘  └──────┬───────┘  └──────┬──────┘ │ │
│  └─────────┼──────────────────┼──────────────────┼────────┘ │
└────────────┼──────────────────┼──────────────────┼──────────┘
             │                  │                  │
             │                  │                  │
    ┌────────▼────────┐  ┌──────▼──────┐  ┌───────▼───────┐
    │ Secrets Store   │  │ EFS Volume  │  │  EBS Volume   │
    │ CSI Driver      │  │ CSI Driver  │  │  CSI Driver   │
    └────────┬────────┘  └──────┬──────┘  └───────┬───────┘
             │                  │                  │
    ┌────────▼────────┐  ┌──────▼──────┐  ┌───────▼───────┐
    │ AWS Secrets     │  │ EFS File    │  │  EBS Volume   │
    │ Manager         │  │ System      │  │  (gp3)        │
    │ (IRSA)          │  │ (Encrypted) │  │  (Encrypted)  │
    └─────────────────┘  └─────────────┘  └───────────────┘
```

## 1. AWS Secrets Manager

### How It Works

1. **Secret Created**: Terraform creates secret in Secrets Manager
2. **SecretProviderClass**: Defines which secrets to mount
3. **CSI Driver**: Mounts secrets as files in pod
4. **Kubernetes Secret**: Auto-synced for env vars
5. **IRSA**: Pod uses IAM role to access Secrets Manager

### Secret Structure

**Secrets Manager (JSON):**
```json
{
  "username": "admin",
  "password": "changeme123",
  "api_key": "secret-api-key-12345"
}
```

**Mounted as Files:**
```
/mnt/secrets/
├── username  (contains: admin)
├── password  (contains: changeme123)
└── api_key   (contains: secret-api-key-12345)
```

**Kubernetes Secret (auto-created):**
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: app-secret-k8s
type: Opaque
data:
  username: YWRtaW4=  # base64 encoded
  password: Y2hhbmdlbWUxMjM=
  api_key: c2VjcmV0LWFwaS1rZXktMTIzNDU=
```

### Usage in Applications

**Method 1: Environment Variables (Recommended)**
```yaml
env:
- name: DB_USERNAME
  valueFrom:
    secretKeyRef:
      name: app-secret-k8s
      key: username
- name: DB_PASSWORD
  valueFrom:
    secretKeyRef:
      name: app-secret-k8s
      key: password
```

**Method 2: File Mounts**
```yaml
volumeMounts:
- name: secrets-store
  mountPath: /mnt/secrets
  readOnly: true

volumes:
- name: secrets-store
  csi:
    driver: secrets-store.csi.k8s.io
    readOnly: true
    volumeAttributes:
      secretProviderClass: app-secrets
```

**Access in Container:**
```bash
# Read from files
cat /mnt/secrets/username
cat /mnt/secrets/password

# Or use environment variables
echo $DB_USERNAME
echo $DB_PASSWORD
```

### SecretProviderClass Configuration

```yaml
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: app-secrets
spec:
  provider: aws
  parameters:
    objects: |
      - objectName: "my-eks-cluster-app-secret"
        objectType: "secretsmanager"
        jmesPath:
          - path: username
            objectAlias: username
          - path: password
            objectAlias: password
          - path: api_key
            objectAlias: api_key
  secretObjects:  # Creates Kubernetes Secret
  - secretName: app-secret-k8s
    type: Opaque
    data:
    - objectName: username
      key: username
    - objectName: password
      key: password
```

### Update Secrets

**In AWS Secrets Manager:**
```bash
aws secretsmanager update-secret \
  --secret-id my-eks-cluster-app-secret \
  --secret-string '{"username":"newuser","password":"newpass","api_key":"new-key"}'
```

**Pods automatically get updated secrets:**
- File mounts: Updated within 2 minutes (CSI driver polling)
- Kubernetes Secret: Updated within 2 minutes
- Environment variables: Require pod restart

**Force pod restart:**
```bash
kubectl rollout restart deployment sample-app
```

## 2. EFS (Elastic File System)

### Characteristics

- **Shared Storage**: Multiple pods can read/write simultaneously
- **Access Mode**: ReadWriteMany (RWX)
- **Use Cases**: Shared files, logs, media, configuration
- **Performance**: Throughput scales with size
- **Encryption**: At rest and in transit

### Storage Class

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: efs-sc
provisioner: efs.csi.aws.com
parameters:
  provisioningMode: efs-ap  # Creates access point per PVC
  fileSystemId: fs-xxxxx
  directoryPerms: "700"
```

### PersistentVolumeClaim

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: efs-pvc
spec:
  accessModes:
    - ReadWriteMany  # Multiple pods can mount
  storageClassName: efs-sc
  resources:
    requests:
      storage: 5Gi  # Soft limit (EFS is elastic)
```

### Usage in Pod

```yaml
spec:
  containers:
  - name: app
    volumeMounts:
    - name: efs-storage
      mountPath: /mnt/efs
  volumes:
  - name: efs-storage
    persistentVolumeClaim:
      claimName: efs-pvc
```

### Example: Shared Log Directory

**Deployment 1 (Writer):**
```yaml
volumeMounts:
- name: shared-logs
  mountPath: /var/log/app
```

**Deployment 2 (Reader):**
```yaml
volumeMounts:
- name: shared-logs
  mountPath: /logs
  readOnly: true
```

Both deployments use the same PVC, so logs written by Deployment 1 are immediately visible to Deployment 2.

### Test EFS

```bash
# Get pod name
POD=$(kubectl get pod -l app=sample-app -o jsonpath='{.items[0].metadata.name}')

# Write to EFS
kubectl exec $POD -- sh -c "echo 'Hello from EFS' > /mnt/efs/test.txt"

# Read from another pod
POD2=$(kubectl get pod -l app=sample-app -o jsonpath='{.items[1].metadata.name}')
kubectl exec $POD2 -- cat /mnt/efs/test.txt
# Output: Hello from EFS
```

## 3. EBS (Elastic Block Store)

### Characteristics

- **Dedicated Storage**: One pod at a time
- **Access Mode**: ReadWriteOnce (RWO)
- **Use Cases**: Databases, stateful apps, persistent data
- **Performance**: Consistent IOPS and throughput
- **Encryption**: At rest
- **Type**: gp3 (general purpose SSD)

### Storage Class

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: ebs-gp3
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
provisioner: ebs.csi.aws.com
volumeBindingMode: WaitForFirstConsumer  # Creates in same AZ as pod
allowVolumeExpansion: true
parameters:
  type: gp3
  encrypted: "true"
```

### PersistentVolumeClaim

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: ebs-pvc
spec:
  accessModes:
    - ReadWriteOnce  # Single pod only
  storageClassName: ebs-gp3
  resources:
    requests:
      storage: 10Gi
```

### Usage in Pod

```yaml
spec:
  containers:
  - name: app
    volumeMounts:
    - name: ebs-storage
      mountPath: /mnt/ebs
  volumes:
  - name: ebs-storage
    persistentVolumeClaim:
      claimName: ebs-pvc
```

### Volume Expansion

**Edit PVC:**
```bash
kubectl patch pvc ebs-pvc -p '{"spec":{"resources":{"requests":{"storage":"20Gi"}}}}'
```

**Verify:**
```bash
kubectl get pvc ebs-pvc
# Shows: 20Gi
```

**No pod restart needed** - filesystem automatically resized.

### Test EBS

```bash
# Get pod name
POD=$(kubectl get pod -l app=aws-cli-app -o jsonpath='{.items[0].metadata.name}')

# Write to EBS
kubectl exec $POD -- sh -c "echo 'Persistent data' > /data/important.txt"

# Delete pod
kubectl delete pod $POD

# New pod gets same volume
POD_NEW=$(kubectl get pod -l app=aws-cli-app -o jsonpath='{.items[0].metadata.name}')
kubectl exec $POD_NEW -- cat /data/important.txt
# Output: Persistent data
```

## Comparison: EFS vs EBS

| Feature | EFS | EBS |
|---------|-----|-----|
| **Access Mode** | ReadWriteMany | ReadWriteOnce |
| **Sharing** | Multiple pods simultaneously | One pod at a time |
| **Performance** | Scales with size | Fixed IOPS/throughput |
| **Use Case** | Shared files, logs | Databases, stateful apps |
| **Cost** | Pay for storage used | Pay for provisioned size |
| **Availability** | Multi-AZ by default | Single AZ |
| **Latency** | Higher (network) | Lower (direct attach) |

## Complete Example: Application with All Features

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: full-featured-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: full-featured-app
  template:
    metadata:
      labels:
        app: full-featured-app
    spec:
      serviceAccountName: app-sa  # IRSA for Secrets Manager
      containers:
      - name: app
        image: nginx:latest
        env:
        # Secrets from Secrets Manager
        - name: DB_USERNAME
          valueFrom:
            secretKeyRef:
              name: app-secret-k8s
              key: username
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: app-secret-k8s
              key: password
        volumeMounts:
        # EFS for shared files
        - name: efs-storage
          mountPath: /shared
        # EBS for persistent data
        - name: ebs-storage
          mountPath: /data
        # Secrets as files
        - name: secrets-store
          mountPath: /mnt/secrets
          readOnly: true
      volumes:
      - name: efs-storage
        persistentVolumeClaim:
          claimName: app-efs-pvc
      - name: ebs-storage
        persistentVolumeClaim:
          claimName: app-ebs-pvc
      - name: secrets-store
        csi:
          driver: secrets-store.csi.k8s.io
          readOnly: true
          volumeAttributes:
            secretProviderClass: app-secrets
```

## Verification Commands

### Check Secrets

```bash
# List secrets
kubectl get secrets

# View secret (base64 encoded)
kubectl get secret app-secret-k8s -o yaml

# Decode secret
kubectl get secret app-secret-k8s -o jsonpath='{.data.username}' | base64 -d

# Check SecretProviderClass
kubectl get secretproviderclass

# View mounted secrets in pod
POD=$(kubectl get pod -l app=sample-app -o jsonpath='{.items[0].metadata.name}')
kubectl exec $POD -- ls -la /mnt/secrets
kubectl exec $POD -- cat /mnt/secrets/username
```

### Check EFS

```bash
# List PVCs
kubectl get pvc

# Check EFS PVC
kubectl describe pvc sample-app-efs-pvc

# View EFS in pod
POD=$(kubectl get pod -l app=sample-app -o jsonpath='{.items[0].metadata.name}')
kubectl exec $POD -- df -h /mnt/efs
kubectl exec $POD -- ls -la /mnt/efs
```

### Check EBS

```bash
# List PVCs
kubectl get pvc

# Check EBS PVC
kubectl describe pvc sample-app-ebs-pvc

# View EBS in pod
POD=$(kubectl get pod -l app=sample-app -o jsonpath='{.items[0].metadata.name}')
kubectl exec $POD -- df -h /mnt/ebs
kubectl exec $POD -- ls -la /mnt/ebs
```

### Check CSI Drivers

```bash
# EFS CSI Driver
kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-efs-csi-driver

# EBS CSI Driver
kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-ebs-csi-driver

# Secrets Store CSI Driver
kubectl get pods -n kube-system -l app=secrets-store-csi-driver
```

## Troubleshooting

### Secrets Not Mounting

**Check service account:**
```bash
kubectl get sa app-sa -o yaml
# Should have eks.amazonaws.com/role-arn annotation
```

**Check IAM role permissions:**
```bash
aws iam get-role-policy --role-name my-eks-cluster-app-role --policy-name app-access
# Should have secretsmanager:GetSecretValue
```

**Check CSI driver logs:**
```bash
kubectl logs -n kube-system -l app=secrets-store-csi-driver
kubectl logs -n kube-system -l app=csi-secrets-store-provider-aws
```

### EFS Mount Failures

**Check EFS mount targets:**
```bash
aws efs describe-mount-targets --file-system-id fs-xxxxx
# Should have one per AZ
```

**Check security group:**
```bash
# Should allow NFS (port 2049) from VPC CIDR
```

**Check CSI driver:**
```bash
kubectl logs -n kube-system -l app.kubernetes.io/name=aws-efs-csi-driver
```

### EBS Volume Not Attaching

**Check node capacity:**
```bash
kubectl describe node
# Check Allocated resources
```

**Check CSI driver:**
```bash
kubectl logs -n kube-system -l app.kubernetes.io/name=aws-ebs-csi-driver
```

**Check PVC events:**
```bash
kubectl describe pvc <pvc-name>
```

## Best Practices

### Secrets
- ✅ Use Secrets Manager for sensitive data
- ✅ Rotate secrets regularly
- ✅ Use environment variables for application config
- ✅ Use file mounts for certificates/keys
- ❌ Don't commit secrets to Git
- ❌ Don't use ConfigMaps for sensitive data

### EFS
- ✅ Use for shared files across pods
- ✅ Use for read-heavy workloads
- ✅ Enable encryption
- ❌ Don't use for databases (use EBS)
- ❌ Don't use for high IOPS workloads

### EBS
- ✅ Use for databases and stateful apps
- ✅ Use gp3 for cost-effective performance
- ✅ Enable encryption
- ✅ Enable volume expansion
- ❌ Don't use for shared storage (use EFS)
- ❌ Don't over-provision (can expand later)

## Cost Optimization

### Secrets Manager
- **Cost:** $0.40/secret/month + $0.05 per 10,000 API calls
- **Optimization:** Use fewer secrets, batch reads

### EFS
- **Cost:** $0.30/GB/month (Standard), $0.025/GB/month (Infrequent Access)
- **Optimization:** Use lifecycle policies, delete unused files

### EBS
- **Cost:** $0.08/GB/month (gp3)
- **Optimization:** Right-size volumes, delete unused volumes

---

**Updated:** January 21, 2026  
**Features:** Secrets Manager, EFS, EBS  
**Status:** Production Ready
