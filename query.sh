#!/bin/sh

PORT_PROMETHEUS=9090
POD_PROMETHEUS=$(kubectl -n istio-system get pod -l app=prometheus -o jsonpath='{.items[0].metadata.name}')

kubectl \
    -n istio-system port-forward \
    "$POD_PROMETHEUS" \
    $PORT_PROMETHEUS:$PORT_PROMETHEUS > /dev/null 2>&1 &

PID=$!
sleep 1

# SERVICES=$(kubectl get svc -o jsonpath='{.items[*].metadata.name}')
# for i in $SERVICES; do
# done

FILTER="reporter=\"destination\",response_code=\"200\""
QUERY_DATA="query=rate(istio_request_duration_milliseconds_sum{$FILTER}[1m]) / rate(istio_request_duration_milliseconds_count{$FILTER}[1m])"
curl --silent 'http://localhost:9090/api/v1/query' --data-urlencode "$QUERY_DATA" | \
jq '.data.result[] | {"destination_app": .metric.destination_app, "source_app": .metric.source_app, "values": .value[1]}'

kill -9 $PID