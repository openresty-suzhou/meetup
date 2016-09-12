#! /bin/bash

# prepare
rm -rf build
mkdir -p build/test/
cp -rf src/ conf/ client/ ssl/ run.sh build/test/
cp Dockerfile build

# build
docker build --force-rm -t openresty-new-feature:test build
