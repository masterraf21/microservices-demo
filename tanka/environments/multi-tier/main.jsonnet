(import "ksonnet-util/kausal.libsonnet") +
(import "hipstershop/hipstershop.libsonnet") +
{

  // the multi-tier project will only create some services wich call services with external URLs
  // You will have to define all the URLs yourself
  //
  // default usage, keeping defaults (same as running 'default' environment):
  // 
  // tk show environments/multi-tier --dangerous-allow-redirect \
  // -e externalURLs='{}' \
  // -e externalApps='[]' \
  // -e project='""' \
  // -e namespace='""'
  // 
  // note the '""' the content inside the '' have to be a valid json object: "" is the empty string
  // 
  // example to create only redis with (useless) external URLs:
  //
  // tk show environments/multi-tier --dangerous-allow-redirect \
  // -e externalURLs='{cartservice: "cart.svc.com:1234", paymentservice: "ici.la:345"}' \
  // -e externalApps='["rediscart"]' \
  // -e project='""' \
  // -e namespace='""'
  //
  // a better example is to install the frontend alone, calling all services in external URLs:
  // 
  // tk show environments/multi-tier --dangerous-allow-redirect \
  // -e externalURLs='{
  //    productcatalogservice: "productcatalogservice.svc.external.com:443",
  //    currencyservice: "currencyservice.svc.external.com:443",
  //    cartservice: "cartservice.svc.external.com:443",
  //    recommendationservice: "recommendationservice.svc.external.com:443",
  //    shippingservice: "shippingservice.svc.external.com:443",
  //    checkoutservice: "checkoutservice.svc.external.com:443",
  //    adservice: "adservice.svc.external.com:443",}' \
  // -e externalApps='["frontend"]' \
  // -e project='""' \
  // -e namespace='""'

  // use an external value to create URLs
  externalURLs:: std.extVar('externalURLs'),

  // select apps from the CLI
  externalApps:: std.extVar('externalApps'),

  project:: std.extVar('project'),
  namespace:: std.extVar('namespace'),

  _config+:: {
    project: if $.project != "" then $.project else "hipstershop-multi-tier",
    namespace: if $.namespace != "" then $.namespace else "hipstershop-multi-tier",
  },

  // all the apps to create
  local apps=if std.length($.externalApps) > 0 then $.externalApps else
    [
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


