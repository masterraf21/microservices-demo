(import "ksonnet-util/kausal.libsonnet") +
(import "hipstershop/hipstershop.libsonnet") +
{
  _config+:: {
    project: "hipstershopistio",
    namespace: self.project,
    default+: {
      env+: {
        ZIPKIN_SERVICE_ADDR: "zipkin.istio-system:9411",
      }
    },
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
    checkoutservice+:{
      deployments+: [
        {name: "checkoutservice-v2", version: "v2", withSvc: false, replica: 1, localEnv:{}},
      ],
    },
    frontend+:{
      deployments+: [
        {name: "frontend-v2", version: "v2", withSvc: false, replica: 1, localEnv:{BANNER_COLOR: "red"}},
      ],
    },
    productcatalogservice+: {
      // namespace+: "hipstershopsvc1",
      env+: {DEMO_DEPLOYMENT_ENV_VAR: "none"},
      deployments+: [
        {name: "productcatalogservice-slow", version: "v2", withSvc: false, replica: 1, localEnv: {EXTRA_LATENCY: "1.5s"}},
        // {name: "productcatalogservice-veryslow", version: "v2", withSvc: false, replica: 1, localEnv: {EXTRA_LATENCY: "5s"}},
      ]
    }, 
    loadgenerator+: {
      env+: {
        FRONTEND_ADDR: "https://hipstershop.add-your-ip.sslip.io",
        FRONTEND_IP: "add-your-ip",
        USERS: "10",
      }
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
