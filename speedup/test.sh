#!/bin/sh

# Exit immediately if a command exits with a non-zero status.
set -e

# TODO: parameter for this time
SLEEP='0.25s';
EXTRA_LATENCY='0.5s';
EXTRA_LATENCY_AND_SLEEP='0.75s';

TIME=$(date '+%Y-%m-%d-%H-%M-%S');

trap ctrl_c INT

ctrl_c() {
    echo 'Clean project'
    clean;
    echo 'Cleaned'
}

setTitle() {
    NAME=$1
    TITLE="$TIME/$NAME" envsubst < k6/k6-config.env.example > k6/k6-config.env
}

init() {
    cd ..
    testNT;
    testAT;
    testDT;
    testDTSi;
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
        kubectl wait po -l group=app --for=delete --timeout=120s
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

    setTitle "$NAME"

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
    kubectl wait po -l group=app --for=condition=ready --timeout=120s
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

### TEST AT ###
testAT() {

    clean;

    createApp;

    stabilization;

    runK6 'AT';
}

### NT TEST ###
testNT() {

    clean;

    # createAppWithLatency;
    createApp;

    ./virtual-service.sh --delay="$EXTRA_LATENCY" --only='productcatalogservice' | kubectl apply -f -

    stabilization;

    runK6 'NT';

}

### DT TEST ###
testDT() {

    clean;

    # createAppWithLatency;
    createApp;

    virtualService "$SLEEP";
    ./virtual-service.sh --delay="$EXTRA_LATENCY_AND_SLEEP" --only='productcatalogservice' | kubectl apply -f -

    stabilization;

    runK6 'DT';
}

### DT(Si) TEST ###
testDTSi() {

    clean;

    # createAppWithLatency;
    createApp;

    virtualService "$SLEEP" 'productcatalogservice';
    ./virtual-service.sh --delay="$EXTRA_LATENCY" --only='productcatalogservice' | kubectl apply -f -

    runK6 'DTSi';
}

init;