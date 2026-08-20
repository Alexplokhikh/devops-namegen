# Kubernetes Reference Manifests

The live Kubernetes workloads are Terraform-managed so that infrastructure, workloads,
persistent storage and monitoring can be destroyed from the same Terraform root.

For assignment submission, exported YAML manifests can be generated after deployment:

```bash
kubectl get deployment namegen -o yaml > k8s/reference/namegen-deployment.yaml
kubectl get service namegen -o yaml > k8s/reference/namegen-service.yaml
kubectl get statefulset mongodb -o yaml > k8s/reference/mongodb-statefulset.yaml
kubectl get service mongodb -o yaml > k8s/reference/mongodb-service.yaml
kubectl get storageclass auto-ebs-gp3 -o yaml > k8s/reference/storage-class.yaml
```

Remove generated runtime-only fields if desired before committing.
