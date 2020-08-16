#!/bin/sh

# exit immediately if a command exits with a non-zero status.
set -e

TEST_TIME_IN_SECONDS=180
KUSTOMIZE='kustomize build kustomize-test'

$KUSTOMIZE | kubectl delete --ignore-not-found=true --wait=true -f -

POD=$(kubectl get po -l app=loadgenerator -o NAME)
if [ -n "$POD" ]; then
    kubectl wait po -l app=loadgenerator --for=delete
fi

$KUSTOMIZE | kubectl apply -f -
sleep 2
kubectl wait po -l app=loadgenerator --for=condition=ready --timeout=120s

echo 'Esperando...'
sleep $TEST_TIME_IN_SECONDS
echo 'Iniciando coleta...'

kubectl logs -l app=loadgenerator -c main --tail=19 > "logs/loadgenerator-$(date +'%d-%m-%Y %T').log"
echo 'Logs coletados'

$KUSTOMIZE | kubectl delete --ignore-not-found=true -f -