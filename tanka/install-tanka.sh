#!/bin/bash

set -xe 

TANKA_VERSION=${TANKA_VERSION:-v0.7.0}
OS=${OS:-linux}
ARCH=${ARCH:-amd64}
DEST=${DEST:-/usr/local/bin}

if [ ! -f "${DEST}/tk" ]; then
  curl -sfSL -o "${DEST}/tk" "https://github.com/grafana/tanka/releases/download/${TANKA_VERSION}/tk-${OS}-${ARCH}"
fi

chmod 755 ${DEST}/tk