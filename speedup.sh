#!/bin/sh

set -e

DELAY=$1

if [ -z "$DELAY" ]; then
    echo 'Missing argument DELAY';
    exit 1;
fi

echo "# DELAY FOR ALL SERVICES: $DELAY"

for i in $(kubectl get svc -o NAME | grep -v kubernetes); do
    echo
    echo '---'
    echo
    BASE="kubectl get $i";
    NAME=$($BASE -o jsonpath='{.metadata.name}');
    PORT=$($BASE -o jsonpath='{.spec.ports[0].port}');
    export NAME
    export PORT
    export DELAY
    envsubst < virtual-service-base.yaml
    unset NAME
    unset PORT
done
