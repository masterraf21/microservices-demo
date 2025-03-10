#!/usr/bin/python
#
# Copyright 2018 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

from concurrent import futures
import argparse
import os
import sys
import time
import grpc
from jinja2 import Environment, FileSystemLoader, select_autoescape, TemplateError
from google.api_core.exceptions import GoogleAPICallError

import demo_pb2
import demo_pb2_grpc
from grpc_health.v1 import health_pb2
from grpc_health.v1 import health_pb2_grpc


from opencensus.ext.grpc import server_interceptor
from opencensus.trace.tracer import Tracer
from opencensus.ext.zipkin.trace_exporter import ZipkinExporter
from opencensus.trace.samplers import AlwaysOnSampler


from logger import getJSONLogger
logger = getJSONLogger('emailservice-server')

# Setup Zipkin exporter
try:
    zipkin_service_addr = os.environ.get("ZIPKIN_SERVICE_ADDR", '')
    if zipkin_service_addr == "":
        logger.info(
            "Skipping Zipkin traces initialization. Set environment variable ZIPKIN_SERVICE_ADDR=<host>:<port> to enable.")
        raise KeyError()
    host, port = zipkin_service_addr.split(":")
    ze = ZipkinExporter(service_name="emailservice-server",
                        host_name=host,
                        port=int(port),
                        endpoint='/api/v2/spans')
    sampler = AlwaysOnSampler()
    tracer = Tracer(exporter=ze, sampler=sampler)
    tracer_interceptor = server_interceptor.OpenCensusServerInterceptor(
        sampler, ze)
    logger.info("Zipkin traces enabled, sending to " + zipkin_service_addr)
except KeyError:
    tracer_interceptor = server_interceptor.OpenCensusServerInterceptor()

# Loads confirmation email template from file
env = Environment(
    loader=FileSystemLoader('templates'),
    autoescape=select_autoescape(['html', 'xml'])
)
template = env.get_template('confirmation.html')


class BaseEmailService(demo_pb2_grpc.EmailServiceServicer):
    def Check(self, request, context):
        return health_pb2.HealthCheckResponse(
            status=health_pb2.HealthCheckResponse.SERVING)


class EmailService(BaseEmailService):
    def __init__(self):
        raise Exception('cloud mail client not implemented')
        super().__init__()

    @staticmethod
    def send_email(client, email_address, content):
        response = client.send_message(
            sender=client.sender_path(project_id, region, sender_id),
            envelope_from_authority='',
            header_from_authority='',
            envelope_from_address=from_address,
            simple_message={
                "from": {
                    "address_spec": from_address,
                },
                "to": [{
                    "address_spec": email_address
                }],
                "subject": "Your Confirmation Email",
                "html_body": content
            }
        )
        logger.info("Message sent: {}".format(response.rfc822_message_id))

    # TODO
    def SendOrderConfirmation(self, request, context):
        extraLatency = os.environ.get('EXTRA_LATENCY')
        if not extraLatency:
            extraLatency = 0
        else:
            extraLatency = int(extraLatency)
        time.sleep(extraLatency/1000)

        email = request.email
        order = request.order

        try:
            confirmation = template.render(order=order)
        except TemplateError as err:
            context.set_details(
                "An error occurred when preparing the confirmation mail.")
            logger.error(err.message)
            context.set_code(grpc.StatusCode.INTERNAL)
            return demo_pb2.Empty()

        try:
            EmailService.send_email(self.client, email, confirmation)
        except GoogleAPICallError as err:
            context.set_details("An error occurred when sending the email.")
            print(err.message)
            context.set_code(grpc.StatusCode.INTERNAL)
            return demo_pb2.Empty()

        return demo_pb2.Empty()


class DummyEmailService(BaseEmailService):
    def SendOrderConfirmation(self, request, context):
        logger.info('A request to send order confirmation email to {} has been received.'.format(
            request.email))
        return demo_pb2.Empty()


class HealthCheck():
    def Check(self, request, context):
        return health_pb2.HealthCheckResponse(
            status=health_pb2.HealthCheckResponse.SERVING)


def start(dummy_mode):
    server = grpc.server(futures.ThreadPoolExecutor(max_workers=10),
                         interceptors=(tracer_interceptor,))
    healthServer = grpc.server(futures.ThreadPoolExecutor(max_workers=10))
    service = None
    if dummy_mode:
        service = DummyEmailService()
    else:
        raise Exception('non-dummy mode not implemented yet')

    demo_pb2_grpc.add_EmailServiceServicer_to_server(service, server)
    health_pb2_grpc.add_HealthServicer_to_server(HealthCheck(), healthServer)

    port = os.environ.get('PORT', "8080")
    logger.info("listening on port: "+port)
    server.add_insecure_port('[::]:'+port)
    server.start()
    healthPort = os.environ.get('HEALTH_PORT', "8081")
    logger.info("listening on port: "+healthPort)
    healthServer.add_insecure_port('[::]:'+healthPort)
    healthServer.start()
    try:
        while True:
            time.sleep(3600)
    except KeyboardInterrupt:
        server.stop(0)
        healthServer.stop(0)


def initStackdriverProfiling():
    project_id = None
    try:
        project_id = os.environ["GCP_PROJECT_ID"]
    except KeyError:
        # Environment variable not set
        pass

    for retry in range(1, 4):
        try:
            if project_id:
                googlecloudprofiler.start(
                    service='email_server', service_version='1.0.0', verbose=0, project_id=project_id)
            else:
                googlecloudprofiler.start(
                    service='email_server', service_version='1.0.0', verbose=0)
            logger.info("Successfully started Stackdriver Profiler.")
            return
        except (BaseException) as exc:
            logger.info(
                "Unable to start Stackdriver Profiler Python agent. " + str(exc))
            if (retry < 4):
                logger.info(
                    "Sleeping %d to retry initializing Stackdriver Profiler" % (retry*10))
                time.sleep(1)
            else:
                logger.warning(
                    "Could not initialize Stackdriver Profiler after retrying, giving up")
    return


if __name__ == '__main__':
    logger.info('starting the email service in dummy mode.')
    start(dummy_mode=True)
