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
      portName: "http",
      image: {
        repo: $._config.image.repo,
        name: "adservice2",
        tag: $._config.image.tag,
      },
      labels: {app: "adservice"},
      env: {
        SRVURL: ":%s" % $._config.adservice.port,
        LOGLEVEL: "debug"
        },
      readinessProbe: container.mixin.readinessProbe.httpGet.withPath("/healthz")
        + container.mixin.readinessProbe.httpGet.withPort(self.port),
      livenessProbe: container.mixin.livenessProbe.httpGet.withPath("/healthz")
        + container.mixin.livenessProbe.httpGet.withPort(self.port),
      limits: container.mixin.resources.withLimits({cpu: "300m", memory: "300Mi"}),
      requests: container.mixin.resources.withRequests({cpu: "200m", memory: "180Mi"}),
      deploymentExtra: deploy.mixin.spec.template.metadata.withAnnotations({"sidecar.istio.io/rewriteAppHTTPProbers": "true"}),
      serviceExtra: {},
    }
  }
}