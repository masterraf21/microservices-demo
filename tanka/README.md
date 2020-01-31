# Hipster Shop templates

This is a templated version of the yamls to deploy the Hipster Shop.

It is based on [Tanka](https://github.com/grafana/tanka), a [Jsonnet](https://jsonnet.org/) tool.

## Overview

The file structure is as follow : 

- vendor: base libs from external providers (ex ksonnet), you should not need to touch this
- `lib/hipstershop/hipstershop.libsonnet`: global description and common variables.
- `lib/hipstershop/*.libsonnet`: each service from the HipsterShop have a specific file here. This is the file to change if you need to modify the deployment values. If you want to only change a variable, override it in the main file of the environment.
- environmens/default/main.jsonnet: the description of the build. You can add, remove or change the things to include in the final yaml file. this is where you are supposed to override some values.

By design, different versions of one micro-service is supposed to be deployed in the same namespace. 

## Build

First [install Tanka](https://tanka.dev/install), then go in the tanka folder.

You need at least Tanka v0.7.0 to be able to use the `--extVar` option needed for the `specific` environment.
It can be installed using (as of 20200121):
```
go get -u github.com/grafana/tanka/cmd/tk@master
```

If the target namespace does not exist, create it:

```bash
kubectl create ns hipstershop1
kubectl label namespace hipstershop1 istio-injection=enabled
```

You can then build the yaml by using the `tk` command line :

```bash
cd test/tcc/hipstershop/tanka
tk show environments/full
```

You can also select a subset of the micro-services:

```bash
tk show environments/full --target deployment/cartservice --target service/cartservice
```

You can save the yaml into a file, or pipe to kubectl to deploy:

```bash
tk show environments/full --dangerous-allow-redirect > ../hipstershop.yaml
```

### using Docker image

You can use the Tanka docker image to build your code:
```
cd tetrate/test/tcc/hipstershop/tanka
docker run -ti --rm -v $(pwd):/tanka grafana/tanka:0.6.2 show tanka/environments/default > /tmp/hipstershop1.yaml
```

## Specific deployments

You can create a new folder under `environments` and add modify the `main.yaml` file to support different deployments.

When creating a new topology, you just have to update the specific part of the `_config`. See `v1-v2` environment files.

### Different versions

When adding multiple versions of the same micro-service, ensure to : 
- change its name
- set the option `withSvc=false` to NOT create another service for this micro-service

ex :

```json
_config+:: {
    project: "hipstershop1",
    namespace: $._config.project,
    adservice+: {
      deployments+: [
        {name: "adservice-v2", version: "v2", withSvc: false},
      ],
      },
    cartservice+: {
      deployments: [],
      },
  },
```

- we add a `v2` version of the app `adservice` because we used `deployments+:`
- we remove all the deployments of `cartservice` as we re-defined it as empty (this will lead to a broken deployment though)

### Different Namespaces

By default this namespace is the name of the `project` and is defined per "environment".

Both Namespace and Project are set to `hipstershop1` for the `default` environment:

```jsonnet
  _config+:: {
    project: "hipstershop1",
    namespace: $._config.project,
    ...
```

#### Global change

You can change the target `namespace` and the `project` of the whole deployment by using the environment `environment/specific`. You *have to* provide the two variables on the commandline:

```bash
tk show environments/specific -e 'project="myproject"' -e 'namespace="mynamespace"'
```

This is usefull when deplying using the `deploy/tcc/06-install-app.sh` script.

#### Specific change

You can change the namespace of each individual micro-service by re-defining it in the `main.jsonnet` of each env: 

```jsonnet
  _config+:: {
    project: "hipstershop1",
    adservice+: {
      namespace: "anotherNS",                         <----
      },
    ...
```

You can also change some core parameters here if you want to test beyond the default deployment. 
You can add any new config parameter, overwriting the default one, or add a `+` to add.
Ex to add more env variables : 

```jsonnet
  _config+:: {
    project: "hipstershop1",
    namespace: $._config.project,
    productcatalogservice+: {
      namespace: "hipstershopsvc1",
      env+: [
        {name: "EXTRA_LATENCY", value: "5.5s"},
      ]
    }, 
  },
```

### Full Distributed Deployment

You can use the _environment_ `multi-tier` to generate more specific deployments. To do so you can define 4 external variables:
1. `-e project='"myNewProjectName"'` will change the project name. This is used to label all the micro-services beeing part of the same project.
1. `-e namespace='"myNewNamespace"'` will globally change the namespace of ALL micro-services.
1. `-e externalURLs='{}'` will allow you to specify the URL for each micro-service individually. This will work in conjuction to the next option.
1. `-e externalApps='[]'` is a list of all the micro-services you want to build.

The idea here is to be able to deploy, for example, the frontend in one cluster, the services in another and Redis in a last one.
To achieve this you will need to run the Tanka build 3 times.

#### Examples

##### Everything in the same cluster

This is equivalent to the `default` environment :

```bash
tk show environments/multi-tier --dangerous-allow-redirect \
  -e externalURLs='{}' \
  -e externalApps='[]' \
  -e project='""' \
  -e namespace='""'
```

note the '""' the content inside the '' have to be a valid json object: "" is the empty string

##### Fontend only

```bash
tk show environments/multi-tier --dangerous-allow-redirect \
  -e project='""' \
  -e namespace='""' \
  -e externalURLs='{
     productcatalogservice: "productcatalogservice.svc.external.com:443",
     currencyservice: "currencyservice.svc.external.com:443",
     cartservice: "cartservice.svc.external.com:443",
     recommendationservice: "recommendationservice.svc.external.com:443",
     shippingservice: "shippingservice.svc.external.com:443",
     checkoutservice: "checkoutservice.svc.external.com:443",
     adservice: "adservice.svc.external.com:443",}' \
  -e externalApps='["frontend"]'
```

##### All services

```bash
tk show environments/multi-tier --dangerous-allow-redirect \
  -e project='""' \
  -e namespace='""' \
  -e externalURLs='{rediscart: "rediscart.svc.external.com:443"}' \
  -e externalApps='[
    "adservice",
    "checkoutservice",
    "emailservice",
    "paymentservice",
    "recommendationservice",
    "shippingservice",
    "cartservice",
    "currencyservice",
    "productcatalogservice"
    ]'
```

##### Redis

```bash
tk show environments/multi-tier --dangerous-allow-redirect \
  -e project='""' \
  -e namespace='""' \
  -e externalURLs='{}' \
  -e externalApps='["rediscart"]'
```

##### Load Generator

```bash
tk show environments/multi-tier --dangerous-allow-redirect \
  -e project='""' \
  -e namespace='""' \
  -e externalURLs='{frontend: "www.hipstershop.external.com:443"}' \
  -e externalApps='["loadgenerator"]'
```