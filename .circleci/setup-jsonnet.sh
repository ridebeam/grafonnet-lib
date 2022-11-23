#!/usr/bin/env bash

curl -L https://github.com/google/go-jsonnet/releases/download/v${JSONNET_VERSION}/go-jsonnet_${JSONNET_VERSION}_Linux_x86_64.tar.gz --output tool.tar.gz
tar -xzf tool.tar.gz
./jsonnet --version
