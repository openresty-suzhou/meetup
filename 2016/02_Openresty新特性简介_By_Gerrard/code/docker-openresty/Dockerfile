FROM centos:7
MAINTAINER gyc.ssdut@gmail.com

COPY depends/  /opt/test/dependency/
COPY install.sh  /opt/test/

WORKDIR /opt/test

RUN yum install -y readline-devel \
		pcre-devel \
		openssl-devel \
		gcc \ 
		make \
		perl \
		&& /opt/test/install.sh \
		&& rm install.sh 

CMD ["/opt/test/openresty/nginx/sbin/nginx", "-g", "daemon off;"]
