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

  // we init this variable to be used when defining URL on the CLI
  externalURLs:: {},

  // set Deployments defaults
  _config+:: {
    repo: "gcr.io/google-samples/microservices-demo",
    adservice+: {
      // compute the URL to reach this service
      URL: if std.objectHas($.externalURLs, self.app) then $.externalURLs[self.app] else "%s.%s:%s" % [self.app, self.namespace, self.port],

      deployments: [
        {name: "adservice", version: "v1", withSvc: true, localEnv:[], replica: 1},
      ],
      },
    cartservice+: {
      // compute the URL to reach this service
      URL: if std.objectHas($.externalURLs, self.app) then $.externalURLs[self.app] else "%s.%s:%s" % [self.app, self.namespace, self.port],

      deployments: [
        {name: "cartservice", version: "v1", withSvc: true, localEnv:[], replica: 1},
      ],
    },
    checkoutservice+: {
      // compute the URL to reach this service
      URL: if std.objectHas($.externalURLs, self.app) then $.externalURLs[self.app] else "%s.%s:%s" % [self.app, self.namespace, self.port],

      deployments: [
        {name: "checkoutservice", version: "v1", withSvc: true, localEnv:[], replica: 1},
      ],
    }, 
    currencyservice+: {
      // compute the URL to reach this service
      URL: if std.objectHas($.externalURLs, self.app) then $.externalURLs[self.app] else "%s.%s:%s" % [self.app, self.namespace, self.port],

      // define default deployment
      deployments: [
        {name: "currencyservice", version: "v1", withSvc: true, localEnv:[], replica: 1},
      ],
    }, 
    emailservice+: {
      // compute the URL to reach this service
      URL: if std.objectHas($.externalURLs, self.app) then $.externalURLs[self.app] else "%s.%s:%s" % [self.app, self.namespace, self.port],

      // define default deployment
      deployments: [
        {name: "emailservice", version: "v1", withSvc: true, localEnv:[], replica: 1},
      ],
    }, 
    frontend+: {
      // compute the URL to reach this service
      URL: if std.objectHas($.externalURLs, self.app) then $.externalURLs[self.app] else "%s.%s:%s" % [self.app, self.namespace, self.port],

      // define default deployment
      deployments: [
        {name: "frontend", version: "v1", withSvc: true, localEnv:[], replica: 1},
      ],
    }, 
    paymentservice+: {
      // compute the URL to reach this service
      URL: if std.objectHas($.externalURLs, self.app) then $.externalURLs[self.app] else "%s.%s:%s" % [self.app, self.namespace, self.port],

      // define default deployment
      deployments: [
        {name: "paymentservice", version: "v1", withSvc: true, localEnv:[], replica: 1},
      ],
    }, 
    productcatalogservice+: {
      // compute the URL to reach this service
      URL: if std.objectHas($.externalURLs, self.app) then $.externalURLs[self.app] else "%s.%s:%s" % [self.app, self.namespace, self.port],

      // define default deployment
      deployments: [
        {name: "productcatalogservice", version: "v1", withSvc: true, localEnv:[], replica: 1},
      ],
    }, 
    recommendationservice+: {
      // compute the URL to reach this service
      URL: if std.objectHas($.externalURLs, self.app) then $.externalURLs[self.app] else "%s.%s:%s" % [self.app, self.namespace, self.port],

      // define default deployment
      deployments: [
        {name: "recommendationservice", version: "v1", withSvc: true, localEnv:[], replica: 1},
      ],
    }, 
    shippingservice+: {
      // compute the URL to reach this service
      URL: if std.objectHas($.externalURLs, self.app) then $.externalURLs[self.app] else "%s.%s:%s" % [self.app, self.namespace, self.port],

      // define default deployment
      deployments: [
        {name: "shippingservice", version: "v1", withSvc: true, localEnv:[], replica: 1},
      ],
    }, 
    rediscart+: {
      // compute the URL to reach this service
      URL: if std.objectHas($.externalURLs, self.app) then $.externalURLs[self.app] else "%s.%s:%s" % [self.app, self.namespace, self.port],

      // define default deployment
      deployments: [
        {name: "redis-cart", version: "v1", withSvc: true, localEnv:[], replica: 1},
      ],
    }, 
    loadgenerator+: {
      // compute the URL to reach this service
      URL: if std.objectHas($.externalURLs, self.app) then $.externalURLs[self.app] else "%s.%s:%s" % [self.app, self.namespace, self.port],

      // define default deployment
      deployments: [
        {name: "loadgenerator", version: "v1", withSvc: false, localEnv:[], replica: 1},
      ],

      // use specific image
      image: {
        repo: "prune",
        name: "loadgenerator",
        tag: "v0.1.4"
      },
    }, 
  },

  local deploy = $.apps.v1.deployment,
  local container = $.core.v1.container,
  local port = $.core.v1.containerPort,
  local service = $.core.v1.service,

  hipstershopApp:: {
    new(type="", name="", version="v1", replica=1, withSvc=false, localEnv=[]):: {
      local config = $._config[type],
      
      local labels = config.labels+{version: version, project: $._config.project},
      deployment: deploy.new(name=name, replicas=1, podLabels=labels, containers=[
        container.new(name, '%s/%s:%s' % [config.image.repo,config.image.name,config.image.tag])
        + container.withPorts(
            [port.new(config.portName, config.port)]
          )
        + config.livenessProbe
        + config.readinessProbe
        + config.limits
        + config.requests
        + container.withEnv(config.env + localEnv)
        + container.withImagePullPolicy("Always")
      ]) 
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

