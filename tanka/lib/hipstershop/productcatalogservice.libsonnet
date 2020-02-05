(import "ksonnet-util/kausal.libsonnet") +
{

  local deploy = $.apps.v1.deployment,
  local container = $.core.v1.container,
  local port = $.core.v1.containerPort,
  local service = $.core.v1.service,

  _config+:: {
    productcatalogservice: {
      app: "productcatalogservice",
      namespace: $._config.namespace, //set a default namespace if not overrided in the main file
      port: 3550,
      portName: "grpc",
      image: {
        repo: $._config.image.repo,
        name: "productcatalogservice",
        tag: $._config.image.tag,
      },
      labels: {app: "productcatalogservice"},
      env: {
        PORT: "%s" % $._config.productcatalogservice.port,
    },
      readinessProbe: container.mixin.readinessProbe.exec.withCommand(["/bin/grpc_health_probe", "-addr=:%s" % self.port,]),
      livenessProbe: container.mixin.livenessProbe.exec.withCommand(["/bin/grpc_health_probe", "-addr=:%s" % self.port,]),
      limits: container.mixin.resources.withLimits({cpu: "200m", memory: "128Mi"}),
      requests: container.mixin.resources.withRequests({cpu: "100m", memory: "64Mi"}),
      deploymentExtra: {},
      serviceExtra: {},
    },
  },
}