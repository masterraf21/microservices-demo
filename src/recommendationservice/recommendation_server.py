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

import os
import random
import time
import traceback
from concurrent import futures

# import googleclouddebugger
# import googlecloudprofiler
import grpc
# from opencensus.trace.exporters import print_exporter
# from opencensus.trace.exporters import stackdriver_exporter
# from opencensus.trace.ext.grpc import server_interceptor
# from opencensus.trace.samplers import always_on

from opencensus.ext.grpc import server_interceptor
from opencensus.trace.tracer import Tracer
from opencensus.ext.zipkin.trace_exporter import ZipkinExporter
from opencensus.trace.samplers import AlwaysOnSampler
from opencensus.trace import config_integration

import demo_pb2
import demo_pb2_grpc
from grpc_health.v1 import health_pb2
from grpc_health.v1 import health_pb2_grpc

from logger import getJSONLogger
logger = getJSONLogger('recommendationservice-server')

# Setup Zipkin exporter
try:
    zipkin_service_addr = os.environ.get("ZIPKIN_SERVICE_ADDR", '')
    if zipkin_service_addr == "":
        logger.info(
            "Skipping Zipkin traces initialization. Set environment variable ZIPKIN_SERVICE_ADDR=<host>:<port> to enable.")
        raise KeyError()
    host, port = zipkin_service_addr.split(":")
    ze = ZipkinExporter(
        service_name="recommendationservice-server",
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


class RecommendationService(demo_pb2_grpc.RecommendationServiceServicer):
    # TODO
    def ListRecommendations(self, request, context):
        extraLatency = os.environ.get('EXTRA_LATENCY')
        if not extraLatency:
            extraLatency = 0
        else:
            extraLatency = int(extraLatency)
        time.sleep(extraLatency/1000)

        max_responses = 5
        # fetch list of products from product catalog stub
        cat_response = product_catalog_stub.ListProducts(demo_pb2.Empty())
        product_ids = [x.id for x in cat_response.products]
        filtered_products = list(set(product_ids)-set(request.product_ids))
        num_products = len(filtered_products)
        num_return = min(max_responses, num_products)
        # sample list of indicies to return
        indices = random.sample(range(num_products), num_return)
        # fetch product ids from indices
        prod_list = [filtered_products[i] for i in indices]
        logger.info(
            "[Recv ListRecommendations] product_ids={}".format(prod_list))
        # build and return response
        response = demo_pb2.ListRecommendationsResponse()
        response.product_ids.extend(prod_list)
        return response

    def Check(self, request, context):
        return health_pb2.HealthCheckResponse(
            status=health_pb2.HealthCheckResponse.SERVING)


if __name__ == "__main__":
    logger.info("initializing recommendationservice")

    port = os.environ.get('PORT', "8080")
    healthPort = os.environ.get('HEALTH_PORT', "8081")
    catalog_addr = os.environ.get('PRODUCT_CATALOG_SERVICE_ADDR', '')
    if catalog_addr == "":
        raise Exception(
            'PRODUCT_CATALOG_SERVICE_ADDR environment variable not set')
    logger.info("product catalog address: " + catalog_addr)
    channel = grpc.insecure_channel(catalog_addr)
    product_catalog_stub = demo_pb2_grpc.ProductCatalogServiceStub(channel)

    # create gRPC server
    server = grpc.server(futures.ThreadPoolExecutor(max_workers=10),
                         interceptors=(tracer_interceptor,))
    healthServer = grpc.server(futures.ThreadPoolExecutor(max_workers=10))

    # add class to gRPC server
    service = RecommendationService()
    demo_pb2_grpc.add_RecommendationServiceServicer_to_server(service, server)
    health_pb2_grpc.add_HealthServicer_to_server(service, healthServer)

    # start server
    logger.info("listening on port: " + port)
    server.add_insecure_port('[::]:'+port)
    server.start()

    logger.info("listening on healthPort: " + healthPort)
    healthServer.add_insecure_port('[::]:'+healthPort)
    healthServer.start()
    # keep alive
    try:
        while True:
            time.sleep(10000)
    except KeyboardInterrupt:
        server.stop(0)
        healthServer.stop(0)
