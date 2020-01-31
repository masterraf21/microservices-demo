(import "ksonnet-util/kausal.libsonnet") +
{

  local deploy = $.apps.v1.deployment,
  local container = $.core.v1.container,
  local port = $.core.v1.containerPort,
  local service = $.core.v1.service,

  _config+:: {
    frontend: {
      app: "frontend",
      namespace: $._config.namespace, //set a default namespace if not overrided in the main file
      port: 8080,
      portName: "http",
      image: {
        repo: $._config.repo,
        name: "frontend",
        tag: "v0.1.3"
      },
      labels: {app: "frontend"},
      env: [
        {name: "PORT", value: "%s" % $._config.frontend.port},
        {name: "PRODUCT_CATALOG_SERVICE_ADDR", value: $._config.productcatalogservice.URL},
        {name: "CURRENCY_SERVICE_ADDR", value: $._config.currencyservice.URL},
        {name: "CART_SERVICE_ADDR", value: $._config.cartservice.URL},
        {name: "RECOMMENDATION_SERVICE_ADDR", value: $._config.recommendationservice.URL},
        {name: "SHIPPING_SERVICE_ADDR", value: $._config.shippingservice.URL},
        {name: "CHECKOUT_SERVICE_ADDR", value: $._config.checkoutservice.URL},
        {name: "AD_SERVICE_ADDR", value: $._config.adservice.URL},
        // {name: "JAEGER_SERVICE_ADDR", value: "jaeger-collector:14268"},
      ],
      readinessProbe: container.mixin.readinessProbe.httpGet.withPath("/_healthz")
        + container.mixin.readinessProbe.httpGet.withPort(self.port)
        + container.mixin.readinessProbe.httpGet.withHttpHeaders({name: "Cookie", value: "shop_session-id=x-readiness-probe"},)
        + container.mixin.readinessProbe.withInitialDelaySeconds(10)
      livenessProbe: container.mixin.livenessProbe.httpGet.withPath("/_healthz")
        + container.mixin.livenessProbe.httpGet.withPort(self.port)
        + container.mixin.livenessProbe.httpGet.withHttpHeaders({name: "Cookie", value: "shop_session-id=x-readiness-probe"},)
        + container.mixin.livenessProbe.withInitialDelaySeconds(10),
      limits: {},
      requests: {},
      deploymentExtra: deploy.mixin.spec.template.metadata.withAnnotations({"sidecar.istio.io/rewriteAppHTTPProbers": "true"}),
      serviceExtra: {},
    },
  },
}