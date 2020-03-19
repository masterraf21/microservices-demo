# adservice2

This is a rewrite of the `adservice` application in Go and using a REST protocol instead of the original JAVA based app using GRPC.

This was added to demonstrate more use-cases then only internal GRPC calls.

## Usage

```bash
Usage of ./adservice2:
  -EXTRA_LATENCY=0s: lattency to add to service response
  -JAEGER_SERVICE_ADDR="": URL to Jaeger Tracing agent
  -ZIPKIN_SERVICE_ADDR="": URL to Zipkin Tracing agent (ex: zipkin:9411)
  -adFile="ads.json": path to the Ads json file
  -logLevel="warn": log level from debug, info, warning, error. When debug, genetate 100% Tracing
  -srvURL=":9555": IP and port to bind, localhost:9555 or :9555
  -version=false: Show version and quit
```

All command line options can be set using env variables by using the same argument in LOWERCASE.


A default `ads.json` file is provided and describes all the possible ads:

```json
  {
    "text": "Film camera for sale. 50% off.", 
    "redirect_url": "/product/2ZYFJ3GM2N", 
    "tags": ["photography","vintage"]
  },
```

The redirect URL is supposed to be a link to an existing product of the Hipstershop
Tags are keywords used to greate pools of adds. When starting, the `adservice2` will load the list of Ads and index them by tags.

## API

### /ad

`curl http://localhost:9555/ad` should return a JSON payload with an array containing a random Ad.

### /ads/<category>

`curl http://localhost:9555/ads/vintage` should return  a JSON payload with an array containing all the ads from a category (having the same tag)

It's the clients role to filter/order the ad it needs.