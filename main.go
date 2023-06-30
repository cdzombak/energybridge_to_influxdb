package main

import (
	"context"
	"encoding/json"
	"flag"
	"fmt"
	"log"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/avast/retry-go"
	"github.com/eclipse/paho.mqtt.golang"
	"github.com/influxdata/influxdb-client-go/v2"
)

type instantaneousUsageMsg struct {
	UnixTimeMs int64 `json:"time"`
	Usage      int   `json:"demand"`
}

const (
	influxTimeout = 3 * time.Second

	energyBridgeNameTag = "energy_bridge_name"

	legacyInstantMeasurementName = "instantaneous_usage"
	newInstantMeasurementName    = "instantaneous_energy_usage"
)

func main() {
	var influxServer = flag.String("influx-server", "", "InfluxDB server, including protocol and port, eg. 'http://192.168.1.1:8086'. Required.")
	var influxOrg = flag.String("influx-org", "", "InfluxDB Org. Required for InfluxDB 2.x.")
	var influxUser = flag.String("influx-username", "", "InfluxDB username. Optional and only for InfluxDB 1.x.")
	var influxPass = flag.String("influx-password", "", "InfluxDB password. Optional and only for InfluxDB 1.x.")
	var influxToken = flag.String("influx-token", "", "InfluxDB token. Required for InfluxDB 2.x.")
	var influxBucket = flag.String("influx-bucket", "", "InfluxDB bucket. Supply a string in the form 'database/retention-policy'. For the default retention policy, pass just a database name (without the slash character). Required.")
	var energyBridgeName = flag.String("energy-bridge-nametag", "", "Value for the energy_bridge_name tag in InfluxDB. Required.")
	var energyBridgeHost = flag.String("energy-bridge-host", "", "IP or host of the Energy Bridge, eg. '192.168.1.1'. Required.")
	var clientId = flag.String("client-id", MustHostname(), "MQTT Client ID. Defaults to hostname.")
	var useNewInstantMeasurementName = flag.Bool("new-measurement-name", false, "Use the new measurement name 'instantaneous_energy_usage' instead of the legacy 'instantaneous_usage'.")
	var printUsage = flag.Bool("print-usage", false, "Log every usage message to standard error.")
	flag.Parse()
	if *influxServer == "" || *influxBucket == "" {
		fmt.Println("-influx-bucket and -influx-server must be supplied.")
		os.Exit(1)
	}
	if *energyBridgeName == "" || *energyBridgeHost == "" {
		fmt.Println("-energy-bridge-host and -energy-bridge-nametag must be supplied.")
		os.Exit(1)
	}

	// end of main() blocks on receiving from `exit` channel;
	// once received it proceeds to exit with the code it received
	exit := make(chan int, 1)
	// Wait for SIGTERM or SIGINT (Ctrl-C), and exit when one is received:
	exitSignal := make(chan os.Signal, 1)
	signal.Notify(exitSignal, syscall.SIGINT, syscall.SIGTERM)
	go func() {
		sig := <-exitSignal
		log.Printf("received signal %s; exiting", sig)
		exit <- 0
	}()

	authString := ""
	if *influxUser != "" || *influxPass != "" {
		authString = fmt.Sprintf("%s:%s", *influxUser, *influxPass)
	} else if *influxToken != "" {
		authString = *influxToken
	}
	influxClient := influxdb2.NewClient(*influxServer, authString)
	ctx, cancel := context.WithTimeout(context.Background(), influxTimeout)
	defer cancel()
	health, err := influxClient.Health(ctx)
	if err != nil {
		log.Fatalf("failed to check InfluxDB health: %v", err)
	}
	if health.Status != "pass" {
		log.Fatalf("InfluxDB did not pass health check: status %s; message '%s'", health.Status, *health.Message)
	}
	influxWriteApi := influxClient.WriteAPIBlocking(*influxOrg, *influxBucket)

	var instantDemandHandler mqtt.MessageHandler = func(client mqtt.Client, msg mqtt.Message) {
		var parsedMsg instantaneousUsageMsg
		if err := json.Unmarshal(msg.Payload(), &parsedMsg); err != nil {
			log.Printf("failed to parse message '%s': %v", msg.Payload(), err)
			return
		}

		atTime := time.Unix(0, parsedMsg.UnixTimeMs*1000000) // milliseconds -> nanoseconds

		if *printUsage {
			log.Printf("usage at %s: %d watts", atTime, parsedMsg.Usage)
		}

		measurementName := legacyInstantMeasurementName
		if *useNewInstantMeasurementName {
			measurementName = newInstantMeasurementName
		}
		point := influxdb2.NewPoint(
			measurementName,
			map[string]string{energyBridgeNameTag: *(energyBridgeName)}, // tags
			map[string]interface{}{"watts": parsedMsg.Usage},            // fields
			atTime,
		)
		if err := retry.Do(
			func() error {
				ctx, cancel := context.WithTimeout(context.Background(), influxTimeout)
				defer cancel()
				return influxWriteApi.WritePoint(ctx, point)
			},
			retry.Attempts(2),
		); err != nil {
			log.Printf("failed to write point to Influx: %v", err)
		}
	}

	broker := fmt.Sprintf("tcp://%s:2883", *energyBridgeHost)
	const topic = "event/metering/instantaneous_demand"

	var connectHandler mqtt.OnConnectHandler = func(client mqtt.Client) {
		log.Printf("connected to %s with client ID %s", broker, *clientId)

		if token := client.Subscribe(topic, 1, instantDemandHandler); token.Wait() && token.Error() != nil {
			log.Fatalf("failed to subscribe to %s: %v", topic, token.Error())
		} else {
			log.Printf("subscribed to topic %s", topic)
		}
	}
	var reconnectHandler mqtt.ReconnectHandler = func(client mqtt.Client, opts *mqtt.ClientOptions) {
		log.Printf("reconnecting to %s ...", broker)
	}
	var connectLostHandler mqtt.ConnectionLostHandler = func(client mqtt.Client, err error) {
		log.Printf("connection lost: %v", err)
	}

	opts := mqtt.NewClientOptions()
	opts.AddBroker(broker)
	opts.SetClientID(*clientId)
	opts.OnConnect = connectHandler
	opts.OnConnectionLost = connectLostHandler
	opts.OnReconnecting = reconnectHandler
	client := mqtt.NewClient(opts)
	if token := client.Connect(); token.Wait() && token.Error() != nil {
		log.Fatalf("failed to connect to %s: %v", broker, token.Error())
	}

	exitCode := <-exit
	log.Printf("shutting down with exit code %d", exitCode)
	os.Exit(exitCode)
}
