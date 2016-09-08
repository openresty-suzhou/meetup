#!/bin/bash

docker run -d -p 1234:1234 -p 4343:4343 -p 8000:8000 -p 8080:8080 openresty-new-feature:test
