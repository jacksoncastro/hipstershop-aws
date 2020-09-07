#!/bin/bash

set -e

DELAY=$1
EXCLUDE=$2

if [ -z "$DELAY" ]; then
    echo 'Missing argument DELAY';
    exit 1;
fi

echo "# DELAY FOR ALL SERVICES: $DELAY"

CMD=(kubectl get svc -o NAME)
CMD+=(\|)
CMD+=(grep -v kubernetes)

if [ -n "$EXCLUDE" ]; then
    CMD+=(\|)
    CMD+=(grep -v "$EXCLUDE")
fi

for i in $(eval "${CMD[@]}"); do
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
