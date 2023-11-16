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

# check for required env vars
if [[ -z "${BRIDGE_HOST}" ]]; then
    die 1 "BRIDGE_HOST is a required environment variable, but is missing"
fi

if [[ -z "${BRIDGE_NAME_TAG}" ]]; then
    die 1 "BRIDGE_NAME_TAG is a required environment variable, but is missing"
fi

if [[ -z "${INFLUX_BUCKET}" ]]; then
    die 1 "INFLUX_BUCKET is a required environment variable, but is missing"
fi

if [[ -z "${INFLUX_SERVER}" ]]; then
    die 1 "INFLUX_SERVER is a required environment variable, but is missing"
fi

# parse envs to create cmd args
args=""

# MQTT Client ID. Defaults to hostname.
if [[ $CLIENT_ID ]]; then
    args="$args -client-id $CLIENT_ID"
fi

# IP or host of the Energy Bridge, eg. '192.168.1.1'. Required.
if [[ $BRIDGE_HOST ]]; then
    args="$args -energy-bridge-host $BRIDGE_HOST"
fi

# Value for the energy_bridge_name tag in InfluxDB. Required.
if [[ $BRIDGE_NAME_TAG ]]; then
    args="$args -energy-bridge-nametag $BRIDGE_NAME_TAG"
fi

# InfluxDB bucket. Supply a string in the form 'database/retention-policy'.
# For the default retention policy, pass just a database name (without the slash character).
# Required.
if [[ $INFLUX_BUCKET ]]; then
    args="$args -influx-bucket $INFLUX_BUCKET"
fi

# InfluxDB server, including protocol and port, eg. 'http://192.168.1.1:8086'. Required.
if [[ $INFLUX_SERVER ]]; then
    args="$args -influx-server $INFLUX_SERVER"
fi

# InfluxDB Org. Required for InfluxDB 2.x.
if [[ $INFLUX_ORG ]]; then
    args="$args -influx-org $INFLUX_ORG"
fi

# InfluxDB username. Optional and only for InfluxDB 1.x.
if [[ $INFLUX_USERNAME ]]; then
    args="$args -influx-username $INFLUX_USERNAME"
fi

# InfluxDB password. Optional and only for InfluxDB 1.x.
if [[ $INFLUX_PASSWORD ]]; then
    args="$args -influx-password $INFLUX_PASSWORD"
fi

# InfluxDB token. Required for InfluxDB 2.x.
if [[ $INFLUX_TOKEN ]]; then
    args="$args -influx-token $INFLUX_TOKEN"
fi

# Use the new measurement name 'instantaneous_energy_usage' instead of the legacy'instantaneous_usage'.
if [[ $NEW_MEASUREMENT_NAME ]]; then
    args="$args -new-measurement-name $NEW_MEASUREMENT_NAME"
fi

# Do not trust the timestamp in MQTT message; instead, use the time the message was received.
if [[ $DISTRUST_MSG_TIMESTAMPS ]]; then
    args="$args -distrust-message-timestamps $DISTRUST_MSG_TIMESTAMPS"
fi

# URL to GET every 30s, if and only if the program has received an MQTT message in the last 60s.
if [[ $HEARTBEAT_URL ]]; then
    args="$args -heartbeat-url \"$HEARTBEAT_URL\""
fi

energybridge_to_influxdb $args
