(import "ksonnet-util/kausal.libsonnet") +
{

  local deploy = $.apps.v1.deployment,
  local container = $.core.v1.container,
  local port = $.core.v1.containerPort,
  local service = $.core.v1.service,

  _config+:: {
    rediscart: {
      app: "redis-cart",
      namespace: $._config.namespace, //set a default namespace if not overrided in the main file
      port: 6379,
      portName: "redis",
      externalURL: "",
      image: {
        repo: "docker.io/library",
        name: "redis",
        tag: "alpine"
      },
      labels: {app: "redis-cart"},
      env: [],
      emptyVolumeMounts: {
          name: "redis-data",
          mountPath: "/data"
      },
      readinessProbe: container.mixin.readinessProbe.tcpSocket.withPort(self.port )
        + container.mixin.readinessProbe.withPeriodSeconds(5),
      livenessProbe: container.mixin.livenessProbe.tcpSocket.withPort(self.port )
        + container.mixin.livenessProbe.withPeriodSeconds(5),
      limits: container.mixin.resources.withLimits({cpu: "200m", memory: "128Mi"}),
      requests: container.mixin.resources.withRequests({cpu: "100m", memory: "64Mi"}),
      deploymentExtra: {},
      serviceExtra: {},
    }
  }
}