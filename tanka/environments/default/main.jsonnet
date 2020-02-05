(import "ksonnet-util/kausal.libsonnet") +
(import "hipstershop/hipstershop.libsonnet") +
{
  _config+:: {
    project: "hipstershop1",
    namespace: $._config.project,
  },

  local apps=[
    "adservice",
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
