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
        repo: $._config.repo,
        name: "productcatalogservice",
        tag: "v0.1.3"
      },
      labels: {app: "loadgenerator"},
      env: [
        {name: "FRONTEND_ADDR", value: "http://%s" % $._config.frontend.URL},
        {name: "USERS", value: "10"},
        // for external HTTPS
        // {name: "FRONTEND_ADDR", value: "https://hipstershop1.tetrate.io:443"},
        // {name: "FRONTEND_IP", value: "104.198.1.148"},
      ],
      readinessProbe: {},
      livenessProbe: {},
      limits: container.mixin.resources.withLimits({cpu: "500m", memory: "512Mi"}),
      requests: container.mixin.resources.withRequests({cpu: "300m", memory: "256Mi"}),
      deploymentExtra: deploy.mixin.spec.template.metadata.withAnnotations({"sidecar.istio.io/rewriteAppHTTPProbers": "true"}),
      serviceExtra: {},
    },
  },
}