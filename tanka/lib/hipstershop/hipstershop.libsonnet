(import "hipstershop/adservice.libsonnet") +
(import "hipstershop/cartservice.libsonnet") +
(import "hipstershop/checkoutservice.libsonnet") +
(import "hipstershop/currencyservice.libsonnet") +
(import "hipstershop/emailservice.libsonnet") +
(import "hipstershop/frontend.libsonnet") +
(import "hipstershop/paymentservice.libsonnet") +
(import "hipstershop/productcatalogservice.libsonnet") +
(import "hipstershop/recommendationservice.libsonnet") +
(import "hipstershop/shippingservice.libsonnet") +
(import "hipstershop/redis.libsonnet") +
(import "hipstershop/loadgenerator.libsonnet") +
{
// global functions

  // envList transforms a {foo: "bar", tic: "tac"} into an array of [{name: "foo", value: "bar"},{name: "tic", value: "tac"},],
  envList(map):: [
    if std.type(map[x]) == "object" then { name: x, valueFrom: map[x] } else { name: x, value: map[x] }
    for x in std.objectFields(map)
  ],

  // set Deployments defaults
  _config+:: {
    image: {
      repo: "gcr.io/google-samples/microservices-demo",
      tag: "v0.1.3",
    },
    // define defaults values to add to each micro-service
    default+: {
      URL:  "%s.%s:%s" % [self.app, self.namespace, self.port],
      env+: {
        ZIPKIN_SERVICE_ADDR: "zipkin.tcc:9411",
      },
    },

    adservice+: {
      deployments: [
        {name: "adservice", version: "v1", withSvc: true, localEnv:{}, replica: 1, image: {}},
      ],
      } + $._config.default,

    cartservice+: {
      deployments: [
        {name: "cartservice", version: "v1", withSvc: true, localEnv:{}, replica: 1, image: {}},
      ],
    } + $._config.default,

    checkoutservice+: {
      deployments: [
        {name: "checkoutservice", version: "v1", withSvc: true, localEnv:{}, replica: 1, image: {}},
      ],
    } + $._config.default, 

    currencyservice+: {
      deployments: [
        {name: "currencyservice", version: "v1", withSvc: true, localEnv:{}, replica: 1, image: {}},
      ],
    } + $._config.default, 

    emailservice+: {
      deployments: [
        {name: "emailservice", version: "v1", withSvc: true, localEnv:{}, replica: 1, image: {}},
      ],
    } + $._config.default,

    frontend+: {
      deployments: [
        {name: "frontend", version: "v1", withSvc: true, localEnv:{}, replica: 1, image: {}},
      ],
    } + $._config.default,

    paymentservice+: {
      deployments: [
        {name: "paymentservice", version: "v1", withSvc: true, localEnv:{}, replica: 1, image: {}},
      ],
    } + $._config.default,

    productcatalogservice+: {
      deployments: [
        {name: "productcatalogservice", version: "v1", withSvc: true, localEnv:{}, replica: 1, image: {}},
      ],
    } + $._config.default,

    recommendationservice+: {
      deployments: [
        {name: "recommendationservice", version: "v1", withSvc: true, localEnv:{}, replica: 1, image: {}},
      ],
    } + $._config.default,

    shippingservice+: {
      deployments: [
        {name: "shippingservice", version: "v1", withSvc: true, localEnv:{}, replica: 1, image: {}},
      ],
    } + $._config.default,

    rediscart+: {
      deployments: [
        {name: "redis-cart", version: "v1", withSvc: true, localEnv:{}, replica: 1, image: {},},
      ],
    } + $._config.default,

    loadgenerator+: {
      deployments: [
        {name: "loadgenerator", version: "v1", withSvc: false, localEnv:{}, replica: 1, image: {}},
      ],
    } + $._config.default,
  },

  local deploy = $.apps.v1.deployment,
  local container = $.core.v1.container,
  local port = $.core.v1.containerPort,
  local service = $.core.v1.service,

  hipstershopApp:: {
    new(type="", name="", version="v1", replica=1, withSvc=false, localEnv={}, image={},):: {
      local config = $._config[type],
      local podImage=if std.length(image)==3 then '%s/%s:%s' % [image.repo,image.name,image.tag] else '%s/%s:%s' % [config.image.repo,config.image.name,config.image.tag],
      local labels = config.labels+{version: version, project: $._config.project},

      deployment: deploy.new(name=name, replicas=1, podLabels=labels, containers=[
        container.new(name, podImage)
        + container.withPorts(
            [port.new(config.portName, config.port)]
          )
        + config.livenessProbe
        + config.readinessProbe
        + config.limits
        + config.requests
        + container.withEnv($.envList(config.env) + $.envList(localEnv))
        + container.withImagePullPolicy("Always")
      ]) 
      + deploy.mixin.metadata.withLabelsMixin(labels)
      + deploy.mixin.metadata.withLabelsMixin(labels)
      + deploy.mixin.metadata.withNamespace(config.namespace)
      + config.deploymentExtra +
      if std.objectHas(config,"emptyVolumeMounts") then
        $.util.emptyVolumeMount(name=config.emptyVolumeMounts.name, path=config.emptyVolumeMounts.mountPath)
      else {},
      
      // create the associated service but don't select on the version
      local svcLabels = config.labels+{project: $._config.project, service: name},
      service: if withSvc then  $.util.serviceFor(self.deployment, ignored_labels=["version","name"], nameFormat="%(port)s-%(container)s")
              + service.mixin.spec.withType("ClusterIP")
              + service.mixin.metadata.withNamespace(config.namespace)
              + service.mixin.metadata.withLabelsMixin(svcLabels,)
              + config.serviceExtra
              else {},
    },
  },
}

