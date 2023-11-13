# energybridge_to_influxdb

Pull electricity usage readings from an Energy Bridge via MQTT and ship them to InfluxDB.

## Usage

The following syntax will run `openweather-influxdb-connector`, and the program will keep running until it's sent a SIGINT or SIGTERM signal.

```text
openweather-influxdb-connector \
    -energy-bridge-host 192.168.1.4 \
    -energy-bridge-nametag "Energy Bridge" \
    -influx-bucket "energy_usage/autogen" \
    -influx-server http://192.168.1.5:8086 \
    [OPTIONS ...]
```

Alternatively, you can run the program via Docker:

```shell
docker run --rm \
    -e BRIDGE_HOST=192.168.1.4 \
    -e BRIDGE_NAME_TAG="Energy Bridge" \
    -e INFLUX_BUCKET="energy_usage/autogen" \
    -e INFLUX_SERVER=http://192.168.1.5:8086 \
    [-e ENV_VAR=VALUE ...] \
    cdzombak/energybridge_to_influxdb:1
```

## Options

* `-client-id`: MQTT Client ID. Defaults to hostname. `CLIENT_ID` env for Docker.
* `-energy-bridge-host`: IP or host of the Energy Bridge, eg. '192.168.1.1'. Required. `BRIDGE_HOST` env for Docker.
* `-energy-bridge-nametag`: Value for the energy_bridge_name tag in InfluxDB. Required. `BRIDGE_NAME_TAG` env for Docker.
* `-influx-bucket`: InfluxDB bucket. Supply a string in the form 'database/retention-policy'. For the default retention policy, pass just a database name (without the slash character). Required. `INFLUX_BUCKET` env for Docker.
* `-influx-org`: InfluxDB org. `INFLUX_ORG` env for Docker. Required for InfluxDB 2.x.
* `-influx-password`: InfluxDB password. `INFLUX_PASSWORD` env for Docker.
* `-influx-server`: InfluxDB server, including protocol and port, e.g. `http://192.168.1.4:8086`. Required. `INFLUX_SERVER` env for Docker.
* `-influx-token`: InfluxDB token. `INFLUX_TOKEN` env for Docker. Required for InfluxDB 2.x.
* `-influx-username`: InfluxDB username. `INFLUX_USERNAME` env for Docker.
* `-new-measurement-name`: Use the new measurement name 'instantaneous_energy_usage' instead of the legacy 'instantaneous_usage'.
* `-distrust-message-timestamps`: Do not trust the timestamp in MQTT message; instead, use the time the message was received.
* `-heartbeat-url`: URL to GET every 30s, if and only if the program has received an MQTT message in the last 60s.
* `-print-usage`: Log every energy usage message to standard error.
* `-help`: Print help and exit.
* `-version`: Print version and exit.

## Installation

### macOS via Homebrew

```shell
brew install cdzombak/oss/energybridge_to_influxdb
```

### Debian via Apt repository

Install my Debian repository if you haven't already:

```shell
sudo apt install ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://dist.cdzombak.net/deb.key | sudo gpg --dearmor -o /etc/apt/keyrings/dist-cdzombak-net.gpg
sudo chmod 0644 /etc/apt/keyrings/dist-cdzombak-net.gpg
echo -e "deb [signed-by=/etc/apt/keyrings/dist-cdzombak-net.gpg] https://dist.cdzombak.net/deb/oss any oss\n" | sudo tee -a /etc/apt/sources.list.d/dist-cdzombak-net.list > /dev/null
sudo apt update
```

Then install `energybridge_to_influxdb` via `apt`:

```shell
sudo apt install energybridge_to_influxdb
```

### Manual installation from build artifacts

Pre-built binaries for Linux and macOS on various architectures are downloadable from each [GitHub Release](https://github.com/cdzombak/energybridge_to_influxdb/releases). Debian packages for each release are available as well.

### Build and install locally

```shell
git clone https://github.com/cdzombak/energybridge_to_influxdb.git
cd energybridge_to_influxdb
make build

cp out/energybridge_to_influxdb $INSTALL_DIR
```

## Docker

A pre-built Docker image available that can be configured entirely via environment variables. [View it on Docker Hub](https://hub.docker.com/r/cdzombak/energybridge_to_influxdb), or pull it via `docker pull cdzombak/energybridge_to_influxdb`.

### Docker environment variables

The following table lists the environment variables that can be used to configure the Docker image.

| Environment Variable      | Equivalent CLI Flag            |
|---------------------------|--------------------------------|
| `CLIENT_ID`               | `-client-id`                   |
| `BRIDGE_HOST`             | `-energy-bridge-host`          |
| `BRIDGE_NAME_TAG`         | `-energy-bridge-nametag`       |
| `INFLUX_BUCKET`           | `-influx-bucket`               |
| `INFLUX_SERVER`           | `-influx-server`               |
| `INFLUX_ORG`              | `-influx-org`                  |
| `INFLUX_USERNAME`         | `-influx-username`             |
| `INFLUX_PASSWORD`         | `-influx-password`             |
| `INFLUX_TOKEN`            | `-influx-token`                |
| `NEW_MEASUREMENT_NAME`    | `-new-measurement-name`        |
| `DISTRUST_MSG_TIMESTAMPS` | `-distrust-message-timestamps` |
| `HEARTBEAT_URL`           | `-heartbeat-url`               |

## Running with Systemd

After installing the binary, you can run it as a systemd service.

- Optionally, create a user for the service to run as: `sudo useradd -r -s /usr/sbin/nologin energybridge_influx_connector`

- Install the systemd service `energybridge-to-influxdb.service` and customize that file as desired (e.g. with the correct CLI options for your deployment):
```shell
curl -sSL https://raw.githubusercontent.com/cdzombak/energybridge_to_influxdb/main/energybridge-to-influxdb.service | sudo tee /etc/systemd/system/energybridge-to-influxdb.service
sudo nano /etc/systemd/system/energybridge-to-influxdb.service
```
- Enable and start the service:
```shell
sudo systemctl daemon-reload
sudo systemctl enable energybridge-to-influxdb
sudo systemctl start energybridge-to-influxdb
```
- Verify its operation:
```shell
sudo systemctl status energybridge-to-influxdb
sudo journalctl -f -u energybridge-to-influxdb.service
```

## Running with Docker

To run as a daemon with Docker, you'll want a command something like:

```shell
docker run -d --rm \
    -e BRIDGE_HOST=192.168.1.4 \
    -e BRIDGE_NAME_TAG="Energy Bridge" \
    -e INFLUX_BUCKET="energy_usage/autogen" \
    -e INFLUX_SERVER=http://192.168.1.5:8086 \
    [-e ENV_VAR=VALUE ...] \
    cdzombak/energybridge_to_influxdb:1
```

You may wish to create [an environment file](https://docs.docker.com/engine/reference/commandline/run/#env) and pass it to Docker via the `--env-file` option:

```shell
docker run -d --rm \
    --env-file /path/to/energybridge_to_influxdb.env \
    cdzombak/energybridge_to_influxdb:1
```

## License

MIT; see `LICENSE` in this repository.

## Author

[Chris Dzombak](https://www.dzombak.com) (GitHub [@cdzombak](https://github.com/cdzombak)).
