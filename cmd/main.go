package main

import (
	"context"
	"flag"
	"fmt"
	"path"
	"time"

	"k8s.io/klog/v2"
	"open-cluster-management.io/api/cloudevents/generic/options/mqtt"
	"open-cluster-management.io/api/cloudevents/work"
	"open-cluster-management.io/api/cloudevents/work/agent/codec"

	"github.com/skeeey/mosquitto/pkg/client"
	"github.com/skeeey/mosquitto/pkg/signal"
)

const (
	certPath = "/home/cloud-user/go/src/github.com/skeeey/mosquitto/certs/domain"
	route    = "mosquitto-mosquitto.apps.server-foundation-sno-r8b9r.dev04.red-chesterfield.com:443"

	startIndex = 1
	counts     = 2
)

func main() {
	caPath := flag.String("ca-path", path.Join(certPath, "root-ca.pem"), "The ca path")
	clientCertPath := flag.String("client-cert-path", path.Join(certPath, "cluster1", "client.pem"), "The client cert path")
	clientKeyPath := flag.String("client-key-path", path.Join(certPath, "cluster1", "client-key.pem"), "The client key path")
	host := flag.String("host", route, "The mqtt host")
	flag.Parse()

	shutdownCtx, cancel := context.WithCancel(context.TODO())
	shutdownHandler := signal.SetupSignalHandler()
	go func() {
		defer cancel()
		<-shutdownHandler
		klog.Infof("\nReceived SIGTERM or SIGINT signal, shutting down controller.\n")
	}()

	ctx, terminate := context.WithCancel(shutdownCtx)
	defer terminate()

	for i := startIndex; i <= counts; i++ {
		go startAgent(ctx, *caPath, *clientCertPath, *clientKeyPath, *host, fmt.Sprintf("cluster%d", i))

		if i%10 == 0 {
			time.Sleep(5 * time.Second)
		}
	}

	<-ctx.Done()
}

func startAgent(ctx context.Context, caPath, clientCertPath, clientKeyPath, host, clusterName string) {
	mqttOptions := mqtt.NewMQTTOptions()
	mqttOptions.BrokerHost = host
	mqttOptions.CAFile = caPath
	mqttOptions.ClientCertFile = clientCertPath
	mqttOptions.ClientKeyFile = clientKeyPath
	mqttOptions.KeepAlive = 10

	clientHolder, err := work.NewClientHolderBuilder(clusterName, mqttOptions).
		WithClusterName(clusterName).
		WithCodecs(codec.NewManifestCodec(nil)).
		NewClientHolder(ctx)
	if err != nil {
		klog.Fatal(err)
	}

	informer := clientHolder.ManifestWorkInformer().Informer()

	controller := client.NewController(informer, clientHolder.ManifestWorks(clusterName))

	go informer.Run(ctx.Done())
	go controller.Run(1, ctx.Done())
}
