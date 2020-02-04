(import "ksonnet-util/kausal.libsonnet") +
{

  local deploy = $.apps.v1.deployment,
  local container = $.core.v1.container,
  local port = $.core.v1.containerPort,
  local service = $.core.v1.service,

  _config+:: {
    cartservice: {
      app: "cartservice",
      namespace: $._config.namespace, //set a default namespace if not overrided in the main file
      port: 7070,
      portName: "grpc",
      image: {
        repo: $._config.repo,
        name: "cartservice",
        tag: "v0.1.3"
      },
      labels: {app: "cartservice"},
      env: {
        REDIS_ADDR: $._config.rediscart.URL,
        PORT: "%s" % $._config.cartservice.port,
        LISTEN_ADDR: "0.0.0.0"
      },
      
      readinessProbe: container.mixin.readinessProbe.exec.withCommand(["/bin/grpc_health_probe", "-addr=:%s" % self.port, "-rpc-timeout=5s"])
                    + container.mixin.readinessProbe.withInitialDelaySeconds(15),
      livenessProbe: container.mixin.livenessProbe.exec.withCommand(["/bin/grpc_health_probe", "-addr=:%s" % self.port, "-rpc-timeout=5s"])
                   + container.mixin.livenessProbe.withInitialDelaySeconds(15),
      limits: container.mixin.resources.withLimits({cpu: "300m", memory: "128Mi"}),
      requests: container.mixin.resources.withRequests({cpu: "200m", memory: "64Mi"}),
      deploymentExtra: {},
      serviceExtra: {},
    },
  },
}