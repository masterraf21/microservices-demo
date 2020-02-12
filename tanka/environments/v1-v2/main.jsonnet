(import "ksonnet-util/kausal.libsonnet") +
(import "hipstershop/hipstershop.libsonnet") +
{
  _config+:: {
    project: "hipstershopv1v2",
    namespace: self.project,
    adservice+: {
      deployments+: [
        {name: "adservice-v2", version: "v2", withSvc: false, replica: 1, localEnv:{}},
      ],
    },
    // cartservice+: {
    //   deployments: [],
    // },
    recommendationservice+: {
      deployments: [
        {name: "recommendationservice", version: "v1", withSvc: true, replica: 2, localEnv:{}},
      ],
    },
    productcatalogservice+: {
      // namespace+: "hipstershopsvc1",
      env+: {DEMO_DEPLOYMENT_ENV_VAR: "none"},
      deployments+: [
        {name: "productcatalogservice-slow", version: "v2", withSvc: false, replica: 1, localEnv: {EXTRA_LATENCY: "5.5s"}},
      ]
    }, 
  },

  // all the apps to create
  local apps=[
    "adservice",
    "apiservice",
    "cartservice",
    "checkoutservice",
    "currencyservice",
    "emailservice",
    "frontend",
    "paymentservice",
    "productcatalogservice",
    "recommendationservice",
    "shippingservice",
    "rediscart",
    "loadgenerator"
  ],

  // generate the code for all applications.
  output: {
    [dep.name]: $.hipstershopApp.new(type=app, name=dep.name, version=dep.version, withSvc=dep.withSvc, localEnv=dep.localEnv, replica=dep.replica) for app in apps for dep in $["_config"][app].deployments
   },
}
