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
Use the script `install-tanka.sh` to install in `/usr/local/lib` (you will need root privileges to do so, or set `DEST=<other destination`>)

It can be installed from source using (as of 20200121):
```
go get -u github.com/grafana/tanka/cmd/tk@0.7.0
```

If the target namespace does not exist, create it:

```bash
kubectl create ns hipstershop1
kubectl label namespace hipstershop1 istio-injection=enabled
```

You can then build the yaml by using the `tk` command line :

```bash
tk show tanka/environments/default
```

You can also select a subset of the micro-services:

```bash
tk show tanka/environments/default --target deployment/cartservice --target service/cartservice
```

You can save the yaml into a file, or pipe to kubectl to deploy:

```bash
tk show tanka/environments/default --dangerous-allow-redirect > /tmp/hipstershop.yaml
```

### using Docker image

You can use the Tanka docker image to build your code:
```
cd tanka
docker run -ti --rm -v $(pwd):/tanka grafana/tanka:0.7.0 show tanka/environments/default > /tmp/hipstershop1.yaml
```
## Full manual deployment

the environment `manual` use two command line variables to manually configure the generated output. Two arguments can be used:
 - `-e selectedApps='[]'`: list the micro-services to include. This is like using the `--target` but is more user friendly when you want multiple microservices
 - `-e manualConfig='{}'`: can be used to redefine all the `_config` variables. This is equivalent as editing the `environment/<name>/main.jsonnet` file


## Specific deployments

You can create a new folder under `environments` and modify the `main.jsonnet` file to support different deployments.

When creating a new topology, you just have to update the specific part of the `_config`. See `v1-v2` environment files.

### Different versions

When adding multiple versions of the same micro-service, ensure to : 
- change its name
- set the option `withSvc=false` to NOT create another service for this micro-service

#### on the command line
This example will only output the `adservice` application, with two deployments, the default `v1` plus a specific `v2` with a specific Image and without a service:

```bash
tk show tanka/environments/manual --dangerous-allow-redirect -e selectedApps='["adservice"]' -e manualConfig='{
  project: "adservice-alone",
  namespace: "splitted",
  adservice+: {
    deployments+: [
      {name: "adservice-v2", version: "v2", withSvc: false, replica: 2, localEnv:{}, image:{
        repo: "myrepo",
        name: "adservice",
        tag: "v0.2"
      }},
    ],
  },
}'
```

#### by changing the environment
Edit the `main.jsonnet` file in one of the envs so:

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

- we add a `v2` version of the app `adservice` because we used a `+` when defining the `deployments`
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

You can change it on the commande line when using the `manual` environment:

```bash
tk show tanka/environments/manual --dangerous-allow-redirect -e selectedApps='[]' -e manualConfig='{
  project: "myproject",
  namespace: "mynamespace",
}'
```

Note that Tanka *DOES NOT* create the Namespace for you

#### Per-Application Specific change

You can change the namespace of each individual micro-service by re-defining it in the environment

#### on the command line

```bash
tk show tanka/environments/manual --dangerous-allow-redirect -e selectedApps='["adservice","cartservice"]' -e manualConfig='{
  adservice+: {
    namespace: "anotherNS",
  },
}'
```

You can also change some core parameters here if you want to test beyond the default deployment. 
You can add any new config parameter, overwriting the default one, or add a `+` to add.
Ex to add more env variables : 

```bash
tk show tanka/environments/manual --dangerous-allow-redirect -e selectedApps='[]' -e manualConfig='{
    project: "hipstershop1",
    namespace: "myNamespace",
    productcatalogservice+: {
      namespace: "hipstershopsvc1",
      env+: {EXTRA_LATENCY: "5.5s"},
    }, 
  }'
```

#### by changing the environment
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
      env+: {EXTRA_LATENCY: "5.5s"},
    }, 
  },
```

### Full Distributed Deployment

You can use the _environment_ `manual` to generate more specific deployments.
The idea here is to be able to deploy the frontend in one cluster, the services in another and Redis in a last one.
To achieve this you will need to run the Tanka build 3 times as each build will generate a single yaml file.

#### Fontend only

```bash
tk show tanka/environments/manual --dangerous-allow-redirect -e selectedApps='["frontend"]' -e manualConfig='{
  productcatalogservice+: {URL: "productcatalogservice.svc.external.com:443"},
  currencyservice+: {URL: "currencyservice.svc.external.com:443"},
  cartservice+: {URL: "cartservice.svc.external.com:443"},
  recommendationservice+: {URL: "recommendationservice.svc.external.com:443"},
  shippingservice+: {URL: "shippingservice.svc.external.com:443"},
  checkoutservice+: {URL: "checkoutservice.svc.external.com:443"},
  adservice+: {URL: "adservice.svc.external.com:443" },
  }' > /tmp/hipstershop-frontend.yaml
```

##### All services

```bash
tk show tanka/environments/manual --dangerous-allow-redirect -e manualConfig='{
  rediscart+: {URL: "rediscart.db-tier.external.com:443"},
  }' \
  -e selectedApps='[
    "adservice",
    "checkoutservice",
    "emailservice",
    "paymentservice",
    "recommendationservice",
    "shippingservice",
    "cartservice",
    "currencyservice",
    "productcatalogservice"
    ]' > /tmp/hipstershop-services.yaml
```

##### Redis

```bash
tk show tanka/environments/manual --dangerous-allow-redirect -e manualConfig='{}' \
  -e selectedApps='["rediscart"]' > /tmp/hipstershop-redis.yaml
```

##### Load Generator

```bash
tk show tanka/environments/manual --dangerous-allow-redirect -e manualConfig='{
  frontend+: {URL: "www.hipstershop.external.com:443"},
}' \
  -e selectedApps='["loadgenerator"]' > /tmp/hipstershop-loadgenerator.yaml
```

### Using your own images

If you built the docker images yourself or want to use a specific release, you can change the repo globally.

```bash
tk show tanka/environments/manual --dangerous-allow-redirect -e selectedApps='[]' -e manualConfig='{
    image+: {
      repo: "myrepo",
      tag: "v0.1.4"
    },
  }'
```

The `Redis` image is coming from DockerHub and is set to `redis:alpine`. If you want to change it you have to specify it explicitelly. Set the Repo value to `docker.io/library` to use images on DockerHub:

```bash
tk show tanka/environments/manual --dangerous-allow-redirect -e selectedApps='["rediscart"]' -e manualConfig='{
    image+: {
      repo: "myrepo",
      tag: "v0.1.4"
    },
    rediscart+: {
      image+: {
        repo: "myrepo",
        name: "redis",
        tag: "latest",
      }
    }
  }'
```