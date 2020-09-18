# K6

## Apply

```bash
kustomize build k6/ | kubectl apply -f -
```

## Delete

```bash
kustomize build k6/ | kubectl delete --ignore-not-found=true -f -
```

## View logs

```bash
 kubectl -n k6 logs -f jobs/k6
```
