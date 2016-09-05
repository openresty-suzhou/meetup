#!/bin/bash

pwd=`pwd`
processor_num=`cat /proc/cpuinfo |grep processor |wc -l`

# Install Openresty
cd ${pwd}/dependency/
if [ ! -d "openresty-1.11.2.1" ]; then
	tar zxvf openresty-1.11.2.1.tar.gz
fi
if [ ! -d "stream-lua-nginx-module" ]; then
	tar zxvf stream-lua-nginx-module.tar.gz
fi
cd openresty-1.11.2.1/
./configure --prefix=${pwd}/openresty --with-http_realip_module \
								--with-ld-opt="-Wl,-rpath,/usr/local/lib" \
								--with-stream \
								--with-stream_ssl_module \
								--add-module=${pwd}/dependency/stream-lua-nginx-module
make -j $processor_num && make install

#
cd ${pwd}
rm -fr dependency/
