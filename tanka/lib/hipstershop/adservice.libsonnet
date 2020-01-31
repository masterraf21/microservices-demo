(import "ksonnet-util/kausal.libsonnet") +
{

  local deploy = $.apps.v1.deployment,
  local container = $.core.v1.container,
  local port = $.core.v1.containerPort,
  local service = $.core.v1.service,

  _config+:: {
    adservice: {
      app: "adservice",
      namespace: $._config.namespace, //set a default namespace if not overrided in the main file
      port: 9555,
      portName: "grpc",
      image: {
        repo: $._config.repo,
        name: "adservice",
        tag: "v0.1.3"
      },
      labels: {app: "adservice"},
      env: [
        {name: "PORT", value: "%s" % $._config.adservice.port},
      ],
      readinessProbe: container.mixin.readinessProbe.exec.withCommand(["/bin/grpc_health_probe", "-addr=:%s" % self.port ]),
      livenessProbe: container.mixin.livenessProbe.exec.withCommand(["/bin/grpc_health_probe", "-addr=:%s" % self.port ]),
      limits: container.mixin.resources.withLimits({cpu: "300m", memory: "300Mi"}),
      requests: container.mixin.resources.withRequests({cpu: "200m", memory: "180Mi"}),
      deploymentExtra: {},
      serviceExtra: {},
    }
  }
}