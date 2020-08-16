# HipsterShop AWS

For create just apply the manifests

```bash
kubectl create -f manifests/
```

For delete the application, run:

```bash
kubectl delete -f manifests/
```

```bash
kubectl label nodes kube-worker-01 group=app
kubectl label nodes kube-worker-02 group=test

kustomize build kustomize-app | kubectl apply -f -
kustomize build kustomize-app | kubectl delete -f -

kustomize build kustomize-test | kubectl apply -f -
kustomize build kustomize-test | kubectl delete -f -
```
