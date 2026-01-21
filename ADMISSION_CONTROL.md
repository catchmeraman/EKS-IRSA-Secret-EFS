# Admission Control with OPA Gatekeeper

## Overview

This deployment includes **OPA Gatekeeper** - a Kubernetes-native policy controller that enforces policies and best practices through admission control webhooks.

## What is Admission Control?

Admission control intercepts requests to the Kubernetes API server **before** objects are persisted, allowing you to:
- ✅ Validate resource configurations
- ✅ Enforce security policies
- ✅ Ensure compliance requirements
- ✅ Block non-compliant resources

## Architecture

```
User/CI → kubectl apply → API Server → Admission Webhook → Gatekeeper
                                              ↓
                                         Evaluate Policy
                                              ↓
                                    Allow / Deny / Mutate
```

## Installed Policies

### 1. Required Labels Policy

**What it does:** Ensures all Deployments have required labels

**Required labels:**
- `app` - Application name
- `environment` - Environment (dev/staging/production)

**Example - BLOCKED:**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
  # Missing labels!
spec:
  ...
```

**Example - ALLOWED:**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
  labels:
    app: my-app
    environment: production
spec:
  ...
```

### 2. Block Privileged Containers

**What it does:** Prevents containers from running in privileged mode

**Blocked configuration:**
```yaml
spec:
  containers:
  - name: app
    securityContext:
      privileged: true  # ❌ BLOCKED
```

**Allowed configuration:**
```yaml
spec:
  containers:
  - name: app
    securityContext:
      privileged: false  # ✅ ALLOWED
    # Or omit privileged entirely
```

### 3. Require Resource Limits

**What it does:** Ensures all containers have CPU and memory limits

**Blocked configuration:**
```yaml
spec:
  containers:
  - name: app
    resources:
      requests:
        cpu: 100m
        memory: 128Mi
      # Missing limits! ❌
```

**Allowed configuration:**
```yaml
spec:
  containers:
  - name: app
    resources:
      requests:
        cpu: 100m
        memory: 128Mi
      limits:
        cpu: 200m      # ✅ Required
        memory: 256Mi  # ✅ Required
```

## Testing Policies

### Test 1: Deploy Without Labels (Should Fail)

```bash
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: test-no-labels
spec:
  replicas: 1
  selector:
    matchLabels:
      app: test
  template:
    metadata:
      labels:
        app: test
    spec:
      containers:
      - name: nginx
        image: nginx
EOF
```

**Expected Result:**
```
Error from server: admission webhook "validation.gatekeeper.sh" denied the request: 
[deployment-must-have-labels] You must provide labels: {"environment"}
```

### Test 2: Deploy Privileged Container (Should Fail)

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: privileged-pod
spec:
  containers:
  - name: nginx
    image: nginx
    securityContext:
      privileged: true
EOF
```

**Expected Result:**
```
Error from server: admission webhook "validation.gatekeeper.sh" denied the request: 
[block-privileged-containers] Privileged container is not allowed: nginx
```

### Test 3: Deploy Without Resource Limits (Should Fail)

```bash
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: no-limits
  labels:
    app: test
    environment: dev
spec:
  replicas: 1
  selector:
    matchLabels:
      app: test
  template:
    metadata:
      labels:
        app: test
    spec:
      containers:
      - name: nginx
        image: nginx
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
EOF
```

**Expected Result:**
```
Error from server: admission webhook "validation.gatekeeper.sh" denied the request: 
[require-resource-limits] Container nginx must have CPU limits
[require-resource-limits] Container nginx must have memory limits
```

### Test 4: Compliant Deployment (Should Succeed)

```bash
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: compliant-app
  labels:
    app: compliant-app
    environment: production
spec:
  replicas: 1
  selector:
    matchLabels:
      app: compliant-app
  template:
    metadata:
      labels:
        app: compliant-app
        environment: production
    spec:
      containers:
      - name: nginx
        image: nginx
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 200m
            memory: 256Mi
EOF
```

**Expected Result:**
```
deployment.apps/compliant-app created
```

## Gatekeeper Commands

### View Installed Policies

```bash
# List constraint templates
kubectl get constrainttemplates

# List constraints
kubectl get constraints

# View specific constraint
kubectl describe k8srequiredlabels deployment-must-have-labels
```

### Check Policy Violations

```bash
# View all violations
kubectl get constraints -o json | jq '.items[].status.violations'

# Check specific constraint violations
kubectl get k8srequiredlabels deployment-must-have-labels -o yaml
```

### Audit Existing Resources

Gatekeeper audits existing resources every 60 seconds:

```bash
# View audit results
kubectl get constraints -o json | jq '.items[] | {name: .metadata.name, violations: .status.totalViolations}'
```

### Disable a Policy Temporarily

```bash
# Delete constraint (keeps template)
kubectl delete k8srequiredlabels deployment-must-have-labels

# Re-enable later
kubectl apply -f constraint.yaml
```

## Creating Custom Policies

### Example: Require Specific Image Registry

```yaml
apiVersion: templates.gatekeeper.sh/v1
kind: ConstraintTemplate
metadata:
  name: k8sallowedrepos
spec:
  crd:
    spec:
      names:
        kind: K8sAllowedRepos
      validation:
        openAPIV3Schema:
          type: object
          properties:
            repos:
              type: array
              items:
                type: string
  targets:
    - target: admission.k8s.gatekeeper.sh
      rego: |
        package k8sallowedrepos
        violation[{"msg": msg}] {
          container := input.review.object.spec.containers[_]
          satisfied := [good | repo = input.parameters.repos[_] ; good = startswith(container.image, repo)]
          not any(satisfied)
          msg := sprintf("Container %v has invalid image repo %v", [container.name, container.image])
        }
---
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sAllowedRepos
metadata:
  name: allowed-repos
spec:
  match:
    kinds:
      - apiGroups: [""]
        kinds: ["Pod"]
  parameters:
    repos:
      - "123456789012.dkr.ecr.us-east-1.amazonaws.com/"
      - "docker.io/library/"
```

## Policy Development Workflow

1. **Write Policy**: Create ConstraintTemplate with Rego
2. **Test Locally**: Use `conftest` or `opa test`
3. **Deploy Template**: `kubectl apply -f template.yaml`
4. **Create Constraint**: `kubectl apply -f constraint.yaml`
5. **Test**: Try to create non-compliant resources
6. **Monitor**: Check audit results

## Best Practices

### Policy Design
- ✅ Start with audit mode (no enforcement)
- ✅ Test policies in dev before production
- ✅ Provide clear error messages
- ✅ Document all policies
- ✅ Version control policy definitions

### Exemptions
Use namespace selectors to exempt system namespaces:

```yaml
spec:
  match:
    kinds:
      - apiGroups: ["apps"]
        kinds: ["Deployment"]
    excludedNamespaces:
      - kube-system
      - gatekeeper-system
```

### Performance
- ✅ Keep policies simple
- ✅ Avoid complex Rego logic
- ✅ Use specific resource kinds
- ✅ Monitor webhook latency

## Monitoring Gatekeeper

### Check Gatekeeper Status

```bash
# Gatekeeper pods
kubectl get pods -n gatekeeper-system

# Webhook configuration
kubectl get validatingwebhookconfigurations | grep gatekeeper

# Gatekeeper logs
kubectl logs -n gatekeeper-system -l control-plane=controller-manager
```

### Metrics

Gatekeeper exposes Prometheus metrics:

```bash
# Port-forward to metrics endpoint
kubectl port-forward -n gatekeeper-system svc/gatekeeper-webhook-service 8888:443

# View metrics
curl -k https://localhost:8888/metrics
```

## Troubleshooting

### Policy Not Working

**Check template:**
```bash
kubectl get constrainttemplate k8srequiredlabels -o yaml
```

**Check constraint:**
```bash
kubectl get k8srequiredlabels deployment-must-have-labels -o yaml
```

**Check webhook:**
```bash
kubectl get validatingwebhookconfigurations gatekeeper-validating-webhook-configuration -o yaml
```

### Webhook Timeout

If deployments hang:

```bash
# Check Gatekeeper pods
kubectl get pods -n gatekeeper-system

# Check logs
kubectl logs -n gatekeeper-system -l control-plane=controller-manager --tail=100
```

### Bypass for Emergency

If Gatekeeper blocks critical deployments:

```bash
# Delete webhook (temporary)
kubectl delete validatingwebhookconfigurations gatekeeper-validating-webhook-configuration

# Deploy your resource
kubectl apply -f critical-deployment.yaml

# Reinstall Gatekeeper
helm upgrade gatekeeper gatekeeper/gatekeeper -n gatekeeper-system
```

## Policy Library

Common policies available:
- Container image scanning
- Pod security standards
- Network policies required
- Ingress whitelist
- Resource quotas
- Namespace labels
- Service mesh requirements

See: https://github.com/open-policy-agent/gatekeeper-library

## Integration with CI/CD

### Pre-commit Validation

```bash
# Install conftest
brew install conftest

# Test manifests locally
conftest test deployment.yaml -p policies/
```

### GitOps Integration

```yaml
# ArgoCD sync policy
apiVersion: argoproj.io/v1alpha1
kind: Application
spec:
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - Validate=true  # Validates against Gatekeeper
```

## Cost Impact

**Gatekeeper Resources:**
- Controller: ~100m CPU, ~256Mi memory
- Audit: ~100m CPU, ~256Mi memory
- Webhook: Minimal latency (<10ms)

**Total:** ~$5-10/month additional cost

## Summary

✅ **Installed**: OPA Gatekeeper with 3 policies  
✅ **Enforced**: Labels, security, resource limits  
✅ **Audited**: Existing resources checked every 60s  
✅ **Extensible**: Easy to add custom policies  

---

**Documentation**: https://open-policy-agent.github.io/gatekeeper/  
**Policy Library**: https://github.com/open-policy-agent/gatekeeper-library
