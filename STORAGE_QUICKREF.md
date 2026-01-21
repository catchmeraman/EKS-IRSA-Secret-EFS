# Storage and Secrets - Quick Reference

## What Was Added

✅ **AWS Secrets Manager** - Secure secret storage and access  
✅ **EFS (Elastic File System)** - Shared storage across pods  
✅ **EBS (Elastic Block Store)** - Persistent block storage  
✅ **CSI Drivers** - Kubernetes integration for all storage types  
✅ **IRSA Integration** - Secure access without credentials  

## Quick Commands

### Check Secrets
```bash
# View mounted secrets
POD=$(kubectl get pod -l app=sample-app -o jsonpath='{.items[0].metadata.name}')
kubectl exec $POD -- ls /mnt/secrets
kubectl exec $POD -- cat /mnt/secrets/username

# Check environment variables
kubectl exec $POD -- env | grep DB_
```

### Test EFS (Shared Storage)
```bash
# Write from pod 1
POD1=$(kubectl get pod -l app=sample-app -o jsonpath='{.items[0].metadata.name}')
kubectl exec $POD1 -- sh -c "echo 'test' > /mnt/efs/file.txt"

# Read from pod 2
POD2=$(kubectl get pod -l app=sample-app -o jsonpath='{.items[1].metadata.name}')
kubectl exec $POD2 -- cat /mnt/efs/file.txt
```

### Test EBS (Persistent Storage)
```bash
# Write data
POD=$(kubectl get pod -l app=aws-cli-app -o jsonpath='{.items[0].metadata.name}')
kubectl exec $POD -- sh -c "echo 'data' > /data/file.txt"

# Delete pod
kubectl delete pod $POD

# Verify data persists in new pod
sleep 10
POD_NEW=$(kubectl get pod -l app=aws-cli-app -o jsonpath='{.items[0].metadata.name}')
kubectl exec $POD_NEW -- cat /data/file.txt
```

### Update Secrets
```bash
# Update in Secrets Manager
aws secretsmanager update-secret \
  --secret-id my-eks-cluster-app-secret \
  --secret-string '{"username":"newuser","password":"newpass","api_key":"new-key"}'

# Restart pods to get new secrets
kubectl rollout restart deployment sample-app
```

## Storage Comparison

| Feature | EFS | EBS |
|---------|-----|-----|
| **Sharing** | Multiple pods | Single pod |
| **Access Mode** | ReadWriteMany | ReadWriteOnce |
| **Use Case** | Shared files | Databases |
| **Performance** | Network-based | Direct-attach |
| **Cost** | $0.30/GB/month | $0.08/GB/month |

## Mount Paths

**In Pods:**
- `/mnt/secrets` - Secrets Manager (read-only)
- `/mnt/efs` - EFS shared storage
- `/mnt/ebs` or `/data` - EBS persistent storage

## Documentation

See **[STORAGE_SECRETS_GUIDE.md](STORAGE_SECRETS_GUIDE.md)** for complete documentation including:
- Architecture diagrams
- Detailed configuration
- Troubleshooting
- Best practices
- Cost optimization

## Verification

```bash
# Check CSI drivers
kubectl get pods -n kube-system | grep csi

# Check storage classes
kubectl get sc

# Check PVCs
kubectl get pvc

# Check secrets
kubectl get secretproviderclass
kubectl get secret app-secret-k8s
```

---
**Features:** Secrets Manager, EFS, EBS  
**Status:** Production Ready
