# adservice2

This is a rewrite of the `adservice` application in Go and using a REST protocol instead of the original JAVA based app using GRPC.

This was added to demonstrate more use-cases then only internal GRPC calls.

## Usage

```bash
Usage of ./adservice2:
  -EXTRA_LATENCY=0s: lattency to add to service response
  -startDelay=0s: delay before service is available (return 503 failed probe)
  -bindDelay=0s: delay before binding the service port at startup
  -consecutiveError=0: number of error 500 to return before answering the call
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

### Errors

when `--consecutiveError=N` is set (ex: `--consecutiveError=3`), calls to `/ad` or `/ads/xxx` will be answered with an error 503 `N` times before the real answer is returned.
If `--consecutiveError=1`, 50% of the requests will be error 503

This is used to demo the Istio `retry` and `circuit-breaker` behaviours.

### Delays
Use `--bindDelay=10s` to delay the start of the server by 10s. During this time the process is running but no network port is opened, so connections attempts will return a `can't connect` error.

Use `--startDelay=10s`to delay the `liveness` by 10s. During this time every Healthz request will get an HTTP error 503.
You can test this by using curl: `curl http://localhost:9555/healthz`

> The `startDelay` time is *ADDED* to the `bindDelay`