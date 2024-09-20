FROM jonasal/nginx-certbot:4.3.0-nginx1.25.2 AS builder

ENV NGINX_VERSION 1.25.2
ENV HEADER_MORE_VERSION 0.33

RUN apt-get update &&  apt-get install --no-install-recommends --no-install-suggests -y \
  gnupg1 \
  ca-certificates \
  gcc \
  libc-dev \
  make \
  openssl\
  curl \
  gnupg \
  wget \
  libpcre3 libpcre3-dev \
  unzip \
  libghc-zlib-dev

RUN wget "http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz" -O nginx.tar.gz && \
    wget "https://github.com/dvershinin/headers-more-nginx-module/archive/refs/tags/v${HEADER_MORE_VERSION}.zip" -O ngx-header-more-${HEADER_MORE_VERSION}.zip && \
    CONF_ARGS=$(nginx -V 2>&1 | sed -n -e 's/^.*arguments: //p') \
    tar -zxC /usr/src -f nginx.tar.gz && \
    unzip ngx-header-more-${HEADER_MORE_VERSION} -d /usr/src && \
    cd /usr/src/nginx-$NGINX_VERSION && \
    ./configure --with-compat $CONF_ARGS --add-dynamic-module=/usr/src/headers-more-nginx-module-${HEADER_MORE_VERSION} && \
    make && make install

FROM jonasal/nginx-certbot:4.3.0-nginx1.25.2

COPY --from=builder /usr/local/nginx/modules/ngx_http_headers_more_filter_module.so /usr/lib/nginx/modules/ngx_http_headers_more_filter_module.so

RUN { echo -n 'load_module modules/ngx_http_headers_more_filter_module.so;'; cat /etc/nginx/nginx.conf; } >/tmp/nginx.conf && mv -f /tmp/nginx.conf /etc/nginx/nginx.conf
