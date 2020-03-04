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
      ports: [
        {portName: "health", port: 5052}
      ],
      image: {
        repo: $._config.image.repo,
        name: "checkoutservice",
        tag: $._config.image.tag,
      },
      labels: {app: "checkoutservice"},
      annotations: {},
      env: {
        PORT: "%s" % $._config.checkoutservice.port,
        HEALTH_PORT: "%s" % $._config.checkoutservice.ports[0].port,
        PRODUCT_CATALOG_SERVICE_ADDR: $._config.productcatalogservice.URL,
        SHIPPING_SERVICE_ADDR: $._config.shippingservice.URL,
        PAYMENT_SERVICE_ADDR: $._config.paymentservice.URL,
        EMAIL_SERVICE_ADDR: $._config.emailservice.URL,
        CURRENCY_SERVICE_ADDR: $._config.currencyservice.URL,
        CART_SERVICE_ADDR: $._config.cartservice.URL,
      },
      readinessProbe: container.mixin.readinessProbe.exec.withCommand(["/bin/grpc_health_probe", "-addr=:%s" % self.ports[0].port ]),
      livenessProbe: container.mixin.livenessProbe.exec.withCommand(["/bin/grpc_health_probe", "-addr=:%s" % self.ports[0].port ]),
      limits: container.mixin.resources.withLimits({cpu: "200m", memory: "128Mi"}),
      requests: container.mixin.resources.withRequests({cpu: "100m", memory: "64Mi"}),
      deploymentExtra: {},
      serviceExtra: {},
    },
  },
}