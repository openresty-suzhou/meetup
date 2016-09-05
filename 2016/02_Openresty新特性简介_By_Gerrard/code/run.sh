#!/bin/bash

if [ ! -d "logs" ]; then
	mkdir -p logs/
fi

./openresty/nginx/sbin/nginx -p . -c conf/nginx.conf -g 'daemon off;'
