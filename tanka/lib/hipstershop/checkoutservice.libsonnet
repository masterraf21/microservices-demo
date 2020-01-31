(import "ksonnet-util/kausal.libsonnet") +
{

  local deploy = $.apps.v1.deployment,
  local container = $.core.v1.container,
  local port = $.core.v1.containerPort,
  local service = $.core.v1.service,

  _config+:: {
    checkoutservice: {
      app: "checkoutservice",
      namespace: $._config.namespace, //set a default namespace if not overrided in the main file
      port: 5050,
      portName: "grpc",
      image: {
        repo: $._config.repo,
        name: "checkoutservice",
        tag: "v0.1.3"
      },
      labels: {app: "checkoutservice"},
      env: [
        {name: "PORT", value: "%s" % $._config.checkoutservice.port},
        {name: "PRODUCT_CATALOG_SERVICE_ADDR", value: $._config.productcatalogservice.URL},
        {name: "SHIPPING_SERVICE_ADDR", value: $._config.shippingservice.URL},
        {name: "PAYMENT_SERVICE_ADDR", value: $._config.paymentservice.URL},
        {name: "EMAIL_SERVICE_ADDR", value: $._config.emailservice.URL},
        {name: "CURRENCY_SERVICE_ADDR", value: $._config.currencyservice.URL},
        {name: "CART_SERVICE_ADDR", value: $._config.cartservice.URL},
        // {name: "JAEGER_SERVICE_ADDR", value: "jaeger-collector:14268"},
      ],
      readinessProbe: container.mixin.readinessProbe.exec.withCommand(["/bin/grpc_health_probe", "-addr=:%s" % self.port ]),
      livenessProbe: container.mixin.livenessProbe.exec.withCommand(["/bin/grpc_health_probe", "-addr=:%s" % self.port ]),
      limits: container.mixin.resources.withLimits({cpu: "200m", memory: "128Mi"}),
      requests: container.mixin.resources.withRequests({cpu: "100m", memory: "64Mi"}),
      deploymentExtra: {},
      serviceExtra: {},
    },
  },
}