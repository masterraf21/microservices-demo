/*
 *
 * Copyright 2015 gRPC authors.
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
 *
 */
// require('@google-cloud/trace-agent').start();

const path = require('path');
const grpc = require('grpc');
const pino = require('pino');

const PROTO_PATH = path.join(__dirname, './proto/demo.proto');
const PORT = 7000;
const HEALTH_PORT = 7001;

const shopProto = grpc.load(PROTO_PATH).hipstershop;
const client = new shopProto.PaymentService(`localhost:${PORT}`,
  grpc.credentials.createInsecure());

const logger = pino({
  name: 'paymentservice-client',
  messageKey: 'message',
  changeLevelName: 'severity',
  useLevelLabels: true
});

const request = {
  amount: {
    currency_code: "USD",
    units: 100,
    nanos: 0
  },
  credit_card: {
    credit_card_number: "11",
    credit_card_cvv: 233,
    credit_card_expiration_year: 22,
    credit_card_expiration_month: 10
  }
};

client.charge(request, (err, response) => {
  if (err) {
    logger.error(`Error in charge: ${err}`);
  } else {
    logger.info(`Transaction Id: ${response.transaction_id}`);
  }
})

const PROTO_HEALTH_PATH = path.join(__dirname, './proto/grpc/health/v1/health.proto');
const healthProto = grpc.load(PROTO_HEALTH_PATH).grpc.health.v1;
const healthClient = new healthProto.Health(`localhost:${HEALTH_PORT}`,
  grpc.credentials.createInsecure());

const healthRequest = {
  service: "grpc"
};

healthClient.Check(healthRequest, (err, response) => {
  if (err) {
    logger.error(`Error in health: ${err}`);
  } else {
    logger.info(`Status is ${response.status}`);
  }

})
