#!/bin/bash
set -e

warn () {
    echo "$@" >&2
}
die () {
    rc=$1
    shift
    warn "$@"
    exit $rc
}

# check for required envs
if [[ -z "${BRIDGE_HOST}" ]]; then
    die 1 "BRIDGE_HOST is a required environment variables that is missing"
fi

if [[ -z "${BRIDGE_NAME_TAG}" ]]; then
    die 1 "BRIDGE_NAME_TAG is a required environment variables that is missing"
fi

if [[ -z "${INFLUX_BUCKET}" ]]; then
    die 1 "BRIDGE_NAME_TAG is a required environment variables that is missing"
fi

if [[ -z "${INFLUX_SERVER}" ]]; then
    die 1 "BRIDGE_NAME_TAG is a required environment variables that is missing"
fi

# parse envs to create cmd args
args=""

if [[ $CLIENT_ID ]]; then
    args="$args -client-id $CLIENT_ID"
fi

if [[ $BRIDGE_HOST ]]; then
    args="$args -energy-bridge-host $BRIDGE_HOST"
fi

if [[ $BRIDGE_NAME_TAG ]]; then
    args="$args -energy-bridge-nametag $BRIDGE_NAME_TAG"
fi

if [[ $INFLUX_BUCKET ]]; then
    args="$args -influx-bucket $INFLUX_BUCKET"
fi

if [[ $INFLUX_SERVER ]]; then
    args="$args -influx-server $INFLUX_SERVER"
fi

if [[ $INFLUX_ORG ]]; then
    args="$args -influx-org $INFLUX_ORG"
fi

if [[ $INFLUX_USERNAME ]]; then
    args="$args -influx-username $INFLUX_USERNAME"
fi

if [[ $INFLUX_PASSWORD ]]; then
    args="$args -influx-password $INFLUX_PASSWORD"
fi

if [[ $INFLUX_TOKEN ]]; then
    args="$args -influx-token $INFLUX_TOKEN"
fi

energybridge_to_influxdb $args
