(import "ksonnet-util/kausal.libsonnet") +
(import "hipstershop/hipstershop.libsonnet") +
{

  // the manual environment allows to re-define everything on the commandline
  //
  // default usage, keeping defaults (same as running 'default' environment):
  // 
  // tk show environments/manual --dangerous-allow-redirect \
  // -e manualConfig='{}' \
  // -e externalApps='[]' 
  // 
  // note you may use '""' notation: the content inside the '' have to be a valid json object: "" is the empty string
  // 
  // example to create only redis with (useless) external URLs:
  //
  // tk show environments/manual --dangerous-allow-redirect \
  // -e manualConfig='{}' \
  // -e externalApps='["rediscart"]'
  //
  // a better example is to install the frontend alone, calling all services in external URLs:
  // 
  // tk show tanka/environments/manual --dangerous-allow-redirect \
  //   -e externalApps='["frontend"]' \
  //   -e manualConfig='{
  //      project: "frontonly",
  //      namespace:"hipstershop-front",
  //      productcatalogservice+: {URL: "productcatalogservice.svc.external.com:443"},
  //      currencyservice+: {URL: "currencyservice.svc.external.com:443"},
  //      cartservice+: {URL: "cartservice.svc.external.com:443"},
  //      recommendationservice+: {URL: "recommendationservice.svc.external.com:443"},
  //      shippingservice+: {URL: "shippingservice.svc.external.com:443"},
  //      checkoutservice+: {URL: "checkoutservice.svc.external.com:443"},
  //      adservice+: {URL: "adservice.svc.external.com:443"},
  //      frontend+: {env+: [{name: "ZIPKIN_SERVICE_ADDR", value: ""}]},
  //      }'

  // tk show environments/manual --dangerous-allow-redirect \
  // -e manualConfig='{
  //      project: "frontonly",
  //      namespace:"hipstershop-front",
  //      productcatalogservice+: {URL: "productcatalogservice.svc.external.com:443"},
  //      currencyservice+: {URL: "currencyservice.svc.external.com:443"},
  //      cartservice+: {URL: "cartservice.svc.external.com:443"},
  //      recommendationservice+: {URL: "recommendationservice.svc.external.com:443"},
  //      shippingservice+: {URL: "shippingservice.svc.external.com:443"},
  //      checkoutservice+: {URL: "checkoutservice.svc.external.com:443"},
  //      adservice+: {URL: "adservice.svc.external.com:443"},
  //      }' /
  // -e externalApps='["frontend"]'

  // use an external value to create URLs
  // externalURLs:: std.extVar('externalURLs'),

  // select apps from the CLI
  externalApps:: std.extVar('externalApps'),

local localConfig=std.extVar('manualConfig'),
// local project=if std.objectHas(localConfig,"project") then localConfig.project else "",
// local namespace=if std.objectHas(localConfig,"namespace") then localConfig.namespace else "",

  _config+:: {
    project: if std.objectHas(localConfig,"project") then localConfig.project else "hipstershop1",
    namespace: if std.objectHas(localConfig,"namespace") then localConfig.namespace else "hipstershop1",
    // project: if project != "" then project else "hipstershop1",
    // namespace: if namespace != "" then namespace else "hipstershop1",
  } + localConfig,

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


