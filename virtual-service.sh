#!/bin/bash

set -e

# parameter 1: message to print in red color
echo_red() {
    echo -e "\033[31;1m$1\033[0m"
}

# parameter 1: message to print in yellow color
echo_yel() {
    echo -e "\033[33;1m$1\033[0m"
}

# parameter 1: message to print in green color
echo_gre() {
    echo -e "\033[32;1m$1\033[0m"
}

function sair() {
    CODE=$1
    MESSAGE=$2

    if [ -z "$CODE" ]; then
        CODE=0
    fi

    if [ -n "$MESSAGE" ]; then
        echo_red "$MESSAGE"
    fi

    exit $CODE;
}

function usage() {
    echo
    echo "Help:"
    echo
    echo "Apply Virtual Services for Services"
    echo
    echo "Examples:"
    echo "    # Show this help"
    echo "    $0 -h"
    echo
    echo '    # Delay of 1s in all services'
    echo "    $0 --delay=1s"
    echo
    echo '    # Delay of 1s in all services, except on shippingservice'
    echo "    $0 --delay=1s --exclude=shippingservice"
    echo
    echo '    # Delay of 1s only on shippingservice'
    echo "    $0 --delay=1s --only=shippingservice"
    echo
    echo 'Parameters:'
    echo '    --help: Show this help'
    echo '    --delay: Delay. Ex.: 1s, 1.0s'
    echo '    --all: Virtual Service for all services'
    echo '    --only: Only service'
    echo '    --exclude: All services except one'
    echo
}

if [ -z "$1" ]; then
    usage
    sair 1 'WARNING: Parameters must be passed.'
fi

while :; do
    case $1 in
        --delay=?*)
            DELAY=${1#*=} # Delete everything up to "=" and assign the remainder.
            ;;
        --delay=) # Handle the case of an empty --delay=
            sair 1 'ERROR: "--delay" requires a non-empty option argument.'
            ;;
        --only=?*)
            ONLY=${1#*=} # Delete everything up to "=" and assign the remainder.
            ;;
        --only=) # Handle the case of an empty --only=
            sair 1 'ERROR: "--only" requires a non-empty option argument.'
            ;;
        --exclude=?*)
            EXCLUDE=${1#*=} # Delete everything up to "=" and assign the remainder.
            ALL=true
            ;;
        --exclude=) # Handle the case of an empty --exclude=
            sair 1 'ERROR: "--exclude" requires a non-empty option argument.'
            ;;
        --all)
            ALL=true
            ;;
        -h|-\?|--help|-help)
            usage
            exit 0
            ;;
        --) # End of all options.
            shift
            break
            ;;
        -?*)
            printf 'WARN: Unknown option (ignored): %s\n' "$1" >&2
            ;;
        *) # Default case: No more options, so break out of the loop.
            break
    esac

    shift
done

getAllServices() {

    FILTER=$1

    CMD=(kubectl get svc -o NAME)
    CMD+=(\|)
    CMD+=(grep -v kubernetes)

    if [ -n "$FILTER" ]; then
        CMD+=(\|)
        CMD+=(grep -v "$FILTER")
    fi

    eval "${CMD[@]}"
}

init() {

    if [ -z "$DELAY" ]; then
        sair 1 'Missing argument DELAY';
    fi

    if [ -z "$ONLY" ] && [ -z "$ALL" ]; then
        ALL=true
    fi

    if [ $ALL ]; then
        SERVICES=$(getAllServices "$EXCLUDE")
    fi

    if [ -n "$ONLY" ]; then
        SERVICES="service/$ONLY"
    fi

    build "$SERVICES"

}

build() {

    SERVICES=$1

    echo "# DELAY ON SERVICES: $DELAY"

    for i in $SERVICES; do
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
}

init;
