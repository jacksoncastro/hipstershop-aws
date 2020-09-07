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

```bash
kubectl create configmap config-hipstershop --from-file=GOOGLE_APPLICATION_CREDENTIALS=./hipstershop.json
kubectl set env --from=configmap/config-hipstershop deploy/recommendationservice
```

```bash
./speedup.sh 2s | kubectl apply -f -
./speedup.sh 2s | kubectl delete -f -

./speedup.sh 2s productcatalogservice | kubectl apply -f -
./speedup.sh 2s productcatalogservice | kubectl delete -f -
```

```bash
kubectl set env deploy productcatalogservice EXTRA_LATENCY-
kubectl set env deploy productcatalogservice EXTRA_LATENCY="2.0s"
```

```bash
kubectl create configmap config-locustfile --from-file locustfile.py
```
