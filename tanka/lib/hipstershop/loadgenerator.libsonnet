(import "ksonnet-util/kausal.libsonnet") +
{

  local deploy = $.apps.v1.deployment,
  local container = $.core.v1.container,
  local port = $.core.v1.containerPort,
  local service = $.core.v1.service,

  _config+:: {
    loadgenerator: {
      app: "loadgenerator",
      namespace: $._config.namespace, //set a default namespace if not overrided in the main file
      port: 8089,
      portName: "http",
      image: {
        repo: $._config.image.repo,
        name: "loadgenerator",
        tag: $._config.image.tag,
      },
      labels: {app: "loadgenerator"},
      env: {
        PYTHONWARNINGS: "ignore",
        FRONTEND_ADDR: "http://%s" % $._config.frontend.URL,
        USERS: "10",
        // FRONTEND_ADDR: "https://hipstershop1.tetrate.io:443",
        // FRONTEND_IP: "104.198.1.148",
    },
      readinessProbe: {},
      livenessProbe: {},
      limits: container.mixin.resources.withLimits({cpu: "500m", memory: "512Mi"}),
      requests: container.mixin.resources.withRequests({cpu: "300m", memory: "256Mi"}),
      deploymentExtra: deploy.mixin.spec.template.metadata.withAnnotations({"sidecar.istio.io/inject": "false"}),
      serviceExtra: {},
    },
  },
}