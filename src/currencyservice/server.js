/*
 * Copyright 2018 Google LLC.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

const path = require("path");
const grpc = require("grpc");
const pino = require("pino");
const protoLoader = require("@grpc/proto-loader");

const MAIN_PROTO_PATH = path.join(__dirname, "./proto/demo.proto");
const HEALTH_PROTO_PATH = path.join(
  __dirname,
  "./proto/grpc/health/v1/health.proto"
);

const PORT = process.env.PORT;

const shopProto = _loadProto(MAIN_PROTO_PATH).hipstershop;
const healthProto = _loadProto(HEALTH_PROTO_PATH).grpc.health.v1;

// tracing stuff
const tracing = require("@opencensus/nodejs");
const { plugin, GrpcPlugin } = require("@opencensus/instrumentation-grpc");
const { ZipkinTraceExporter } = require("@opencensus/exporter-zipkin");
const { ConsoleExporter } = require("@opencensus/core");
const tracer = setupTracerAndExporters();

const logger = pino({
  name: "currencyservice-server",
  messageKey: "message",
  changeLevelName: "severity",
  useLevelLabels: true,
});

var extraLatency = process.env["EXTRA_LATENCY"];

/**
 * Helper function that loads a protobuf file.
 */
function _loadProto(path) {
  const packageDefinition = protoLoader.loadSync(path, {
    keepCase: true,
    longs: String,
    enums: String,
    defaults: true,
    oneofs: true,
  });
  return grpc.loadPackageDefinition(packageDefinition);
}

/**
 * Helper function that gets currency data from a stored JSON file
 * Uses public data from European Central Bank
 */
function _getCurrencyData(callback) {
  const data = require("./data/currency_conversion.json");
  callback(data);
}

/**
 * Helper function that handles decimal/fractional carrying
 */
function _carry(amount) {
  const fractionSize = Math.pow(10, 9);
  amount.nanos += (amount.units % 1) * fractionSize;
  amount.units =
    Math.floor(amount.units) + Math.floor(amount.nanos / fractionSize);
  amount.nanos = amount.nanos % fractionSize;
  return amount;
}

function _newTraceOptions(name, metadata) {
  const traceOptions = {
    name: name,
    kind: "SERVER",
  };

  const spanContext = GrpcPlugin.getSpanContext(metadata);
  if (spanContext) {
    traceOptions.spanContext = spanContext;
  }
  logger.info("path func: %s", JSON.stringify(traceOptions));
  return traceOptions;
}
/**
 * Lists the supported currencies
 */
function getSupportedCurrencies(call, callback) {
  tracer.startRootSpan(
    _newTraceOptions(
      "grpc.hipstershop.CurrencyService/GetSupportedCurrencies",
      call.metadata
    ),
    (rootSpan) => {
      logger.info("Getting supported currencies...");
      _getCurrencyData((data) => {
        callback(null, { currency_codes: Object.keys(data) });
      });
      rootSpan.end();
    }
  );
}

/**
 * Converts between currencies
 */
// TODO
function convert(call, callback) {
  tracer.startRootSpan(
    _newTraceOptions("grpc.hipstershop.CurrencyService/Convert", call.metadata),
    (rootSpan) => {
      await sleep(extraLatency)
      logger.info("received conversion request");
      try {
        _getCurrencyData((data) => {
          const request = call.request;

          // Convert: from_currency --> EUR
          const from = request.from;
          const euros = _carry({
            units: from.units / data[from.currency_code],
            nanos: from.nanos / data[from.currency_code],
          });

          euros.nanos = Math.round(euros.nanos);

          // Convert: EUR --> to_currency
          const result = _carry({
            units: euros.units * data[request.to_code],
            nanos: euros.nanos * data[request.to_code],
          });

          result.units = Math.floor(result.units);
          result.nanos = Math.floor(result.nanos);
          result.currency_code = request.to_code;

          logger.info(`conversion request successful`);
          callback(null, result);
        });
      } catch (err) {
        logger.error(`conversion request failed: ${err}`);
        callback(err.message);
      }
      rootSpan.end();
    }
  );
}

/**
 * Endpoint for health checks
 */
function check(call, callback) {
  callback(null, { status: "SERVING" });
}

/*
 * Sleep in milisecond of argument
 */
function sleep(ms) {
  logger.info(`Sleeping for ${ms} ms`);
  return new Promise((resolve) => {
    setTimeout(resolve, ms);
  });
}

/**
 * Starts an RPC server that receives requests for the
 * CurrencyConverter service at the sample server port
 */
function main() {
  logger.info(`Starting gRPC server on port ${PORT}...`);

  if (!extraLatency) {
    extraLatency = 0;
  } else {
    extraLatency = parseInt(extraLatency);
  }

  const server = new grpc.Server();
  server.addService(shopProto.CurrencyService.service, {
    getSupportedCurrencies,
    convert,
  });
  server.addService(healthProto.Health.service, { check });
  server.bind(`0.0.0.0:${PORT}`, grpc.ServerCredentials.createInsecure());
  server.start();
}

function setupTracerAndExporters() {
  // grab Zipkin address from env variables
  const ZIPKIN_SERVICE_ADDR = process.env["ZIPKIN_SERVICE_ADDR"];

  const zipkinOptions = {
    url: "http://" + ZIPKIN_SERVICE_ADDR + "/api/v2/spans",
    serviceName: "currencyservice",
  };

  const defaultBufferConfig = {
    bufferSize: 1,
    bufferTimeout: 20000, // time in milliseconds
  };

  let exporter;

  if (ZIPKIN_SERVICE_ADDR) {
    // Creates Zipkin exporter
    exporter = new ZipkinTraceExporter(zipkinOptions);
  } else {
    // Console exporter can print spans to stdout
    exporter = new ConsoleExporter(defaultBufferConfig);
  }

  // Starts Stackdriver exporter
  tracing.registerExporter(exporter).start();

  // Starts tracing and set sampling rate
  const tracer = tracing.start({
    samplingRate: 1, // For demo purposes, always sample
  }).tracer;

  // Defines basedir and version
  const basedir = path.dirname(require.resolve("grpc"));
  const version = require(path.join(basedir, "package.json")).version;

  // Enables GRPC plugin: Method that enables the instrumentation patch.
  // plugin.enable(grpc, tracer, version, /** plugin options */{}, basedir);

  return tracer;
}

main();
