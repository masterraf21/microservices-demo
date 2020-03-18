module github.com/tetratelabs/microservices-demo/src/adservice2

go 1.14

require (
	contrib.go.opencensus.io/exporter/jaeger v0.2.0
	contrib.go.opencensus.io/exporter/prometheus v0.1.0
	contrib.go.opencensus.io/exporter/zipkin v0.1.1
	github.com/gorilla/mux v1.7.4
	github.com/namsral/flag v1.7.4-pre
	github.com/openzipkin/zipkin-go v0.2.2
	github.com/pkg/errors v0.9.1
	github.com/sirupsen/logrus v1.4.2
	github.com/tetratelabs/microservices-demo/src/frontend v0.0.0-20200311111845-50934932798e
	go.opencensus.io v0.22.2
)
