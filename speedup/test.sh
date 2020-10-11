#!/bin/sh

# Exit immediately if a command exits with a non-zero status.
set -e

# in seconds
EXTRA_LATENCY='0.2s'
PERFORMANCE_GAIN='0.1s'

UNITY=$(echo "$EXTRA_LATENCY" | grep -i -E -o '(ms|s)$')
SUM_EXTRA_GAIN=$(echo $EXTRA_LATENCY $PERFORMANCE_GAIN "$UNITY" | awk '{sum_var=($1 + $2); print sum_var $3}')
SUB_EXTRA_GAIN=$(echo $EXTRA_LATENCY $PERFORMANCE_GAIN "$UNITY" | awk '{sub_var=($1 - $2); print sub_var $3}')

TIME=$(date '+%Y-%m-%d-%H-%M-%S');
ITERATIONS=5

trap ctrl_c INT

ctrl_c() {
    echo 'Clean project'
    clean;
    echo 'Cleaned'
}

setTitle() {
    NAME=$1
    ITERATION=$2
    TITLE="$TIME/$NAME" ITERATION="$ITERATION" envsubst < k6/k6-config.env.example > k6/k6-config.env
}

init() {
    cd ..
    for i in $(seq 1 $ITERATIONS); do
        echo "Begin iteration number $i";
        testNT "$i";
        testAT "$i";
        testDT "$i";
        testDTSi "$i";
        echo "Ending iteration number $i";
    done
    clean;
}

deleteTest() {
    echo 'Deleting test'
    kustomize build k6/ | kubectl delete --ignore-not-found=true -f -
    echo 'Deleted test'
}

deleteVirtualServices() {
    echo 'Deleting virtual services...'
    ./virtual-service.sh --delay=0s | kubectl delete --ignore-not-found=true -f -
    echo 'Deleted virtual services.'
}

deleteApp() {

    echo 'Deleting app...'

    kustomize build kustomize-app | \
    kubectl delete --ignore-not-found=true -f -

    POD=$(kubectl get po -l group=app -o NAME)
    if [ -n "$POD" ]; then
        echo 'Wait delete...'
        kubectl wait po -l group=app --for=delete --timeout=1800s
    fi

    echo 'Deleted app.'
}

stabilization() {
    echo 'Wait for stabilization'
    sleep 20
    echo 'Done!'
}

clean() {
    deleteTest;
    deleteVirtualServices;
    deleteApp;
}

runK6() {

    NAME=$1
    ITERATION=$2

    setTitle "$NAME" "$ITERATION"

    echo "Creating teste k6 - $NAME"
    kustomize build k6/ | kubectl apply -f -
    echo "Created teste k6 - $NAME"

    echo "Wait test $NAME"
    kubectl -n k6 wait job/k6 --for=condition=complete --timeout=1800s
    echo "Fineshed test $NAME"

}

# CREATE APP
createApp() {

    echo 'Create project'
    kustomize build kustomize-app | \
    kubectl apply -f -

    echo 'Wait create...'
    sleep 1
    kubectl wait po -l group=app --for=condition=ready --timeout=1800s
    echo 'Created'
}

# createAppWithLatency() {

#     createApp;

#     echo "Set EXTRA_LATENCY to $SLEEP"
#     kubectl set env deploy productcatalogservice EXTRA_LATENCY="$SLEEP"

#     echo 'Wait pod productcatalogservice...'
#     kubectl wait po -l app=productcatalogservice --for=condition=ready --timeout=120s
#     echo 'Done'
# }

virtualService() {

    DELAY=$1
    EXCLUDE=$2

    if [ -n "$EXCLUDE" ]; then
        ./virtual-service.sh --delay="$DELAY" --exclude="$EXCLUDE" | kubectl apply -f -
    else
        ./virtual-service.sh --delay="$DELAY" | kubectl apply -f -
    fi
}

virtualServiceOnly() {

    DELAY=$1
    ONLY=$2

    ./virtual-service.sh --delay="$DELAY" --only="$ONLY" | kubectl apply -f -
}

### NT TEST ###
testNT() {

    ITERATION=$1

    clean;

    # createAppWithLatency;
    createApp;

    virtualServiceOnly "$EXTRA_LATENCY" 'productcatalogservice';

    stabilization;

    runK6 'NT' "$ITERATION";

}

### TEST AT ###
testAT() {

    ITERATION=$1

    clean;

    createApp;

    virtualServiceOnly "$SUB_EXTRA_GAIN" 'productcatalogservice';

    stabilization;

    runK6 'AT' "$ITERATION";
}

### DT TEST ###
testDT() {

    ITERATION=$1

    clean;

    # createAppWithLatency;
    createApp;

    virtualService "$PERFORMANCE_GAIN";
    virtualServiceOnly "$SUM_EXTRA_GAIN" 'productcatalogservice'

    stabilization;

    runK6 'DT' "$ITERATION";
}

### DT(Si) TEST ###
testDTSi() {

    ITERATION=$1

    clean;

    # createAppWithLatency;
    createApp;

    virtualService "$PERFORMANCE_GAIN" 'productcatalogservice';
    virtualServiceOnly "$EXTRA_LATENCY" 'productcatalogservice'

    runK6 'DTSi' "$ITERATION";
}

init;