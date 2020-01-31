(import "ksonnet-util/kausal.libsonnet") +
{

  local deploy = $.apps.v1.deployment,
  local container = $.core.v1.container,
  local port = $.core.v1.containerPort,
  local service = $.core.v1.service,

  _config+:: {
    recommendationservice: {
      app: "recommendationservice",
      namespace: $._config.namespace, //set a default namespace if not overrided in the main file
      port: 8080,
      portName: "grpc",
      image: {
        repo: $._config.repo,
        name: "recommendationservice",
        tag: "v0.1.3"
      },
      labels: {app: "recommendationservice"},
      env: [
        {name: "PORT", value: "%s" % $._config.recommendationservice.port},
        {name: "PRODUCT_CATALOG_SERVICE_ADDR", value: $._config.productcatalogservice.URL},
        {name: "ENABLE_PROFILER", value: "0"},
      ],
      readinessProbe: container.mixin.readinessProbe.exec.withCommand(["/bin/grpc_health_probe", "-addr=:%s" % self.port,]),
      livenessProbe: container.mixin.livenessProbe.exec.withCommand(["/bin/grpc_health_probe", "-addr=:%s" % self.port,]),
      limits: container.mixin.resources.withLimits({cpu: "200m", memory: "450Mi"}),
      requests: container.mixin.resources.withRequests({cpu: "100m", memory: "220Mi"}),
      deploymentExtra: {},
      serviceExtra: {},
    },
  },
}