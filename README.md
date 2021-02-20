# energybridge_to_influxdb

Pull instantaneous electricity usage readings from an Energy Bridge via MQTT and ship them to InfluxDB.

## Build

```shell
go build -o ./energybridge_to_influxdb .
```

## Install (systemd)

- Build on the target system, or use [Go's cross compilation](https://dave.cheney.net/2015/08/22/cross-compilation-with-go-1-5) to build for the target system
- Create a user for the service to run as: `sudo useradd -r -U energybridge_influx_connector`
- Copy the binary to `/usr/local/bin`
- `sudo chown energybridge_influx_connector:energybridge_influx_connector /usr/local/bin/energybridge_to_influxdb`
- Install the systemd service `energybridge-to-influxdb.service` and customize that file:
```shell
sudo cp energybridge-to-influxdb.service /etc/systemd/system
sudo chown root:root /etc/systemd/system/energybridge-to-influxdb.service
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

## Usage

* `-client-id`: MQTT Client ID. Defaults to hostname. `CLIENT_ID` env for Docker.
* `-energy-bridge-host`: IP or host of the Energy Bridge, eg. '192.168.1.1'. Required. `BRIDGE_HOST` env for Docker.
* `-energy-bridge-nametag`: Value for the energy_bridge_name tag in InfluxDB. Required. `BRIDGE_NAME_TAG` env for Docker.
* `-influx-bucket`: InfluxDB bucket. Supply a string in the form 'database/retention-policy'. For the default retention policy, pass just a database name (without the slash character). Required. `INFLUX_BUCKET` env for Docker.
* `-influx-password`: InfluxDB password. `INFLUX_PASSWORD` env for Docker.
* `-influx-server`: InfluxDB server, including protocol and port, eg. 'http://192.168.1.1:8086'. Required. `INFLUX_SERVER` env for Docker.
* `-influx-username`: InfluxDB username. `INFLUX_USERNAME` env for Docker.
* `-print-usage`: Pass this flag to log every usage message to standard error.

## Docker

A docker image is also provided that can be configured via environment variables.

## License

MIT; see `LICENSE` in this repository.

## Author

[Chris Dzombak](https://www.dzombak.com) (GitHub [@cdzombak](https://github.com/cdzombak)).
