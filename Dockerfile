# syntax=docker/dockerfile:1.7@sha256:a57df69d0ea827fb7266491f2813635de6f17269be881f696fbfdf2d83dda33e

ARG SOURCE_DATE_EPOCH=1766416952

FROM jonasal/nginx-certbot:6.2.0-nginx1.31.5@sha256:133f39cd8897f6987b56d1f6a182ec7ec4173490c10009a745a91dc94e0e9de4 AS module-builder

ARG SOURCE_DATE_EPOCH

# The base image was built from the 2026-08-24 Debian snapshot. Reusing that
# immutable snapshot prevents later package repository changes from changing
# the module build environment.
RUN set -eux; \
    rm -f /etc/apt/sources.list.d/debian.sources; \
    printf '%s\n' \
      'Types: deb' \
      'URIs: https://snapshot.debian.org/archive/debian/20260824T000000Z' \
      'Suites: trixie trixie-updates' \
      'Components: main' \
      'Signed-By: /usr/share/keyrings/debian-archive-keyring.pgp' \
      '' \
      'Types: deb' \
      'URIs: https://snapshot.debian.org/archive/debian-security/20260824T000000Z' \
      'Suites: trixie-security' \
      'Components: main' \
      'Signed-By: /usr/share/keyrings/debian-archive-keyring.pgp' \
      > /etc/apt/sources.list.d/debian-snapshot.sources; \
    apt-get -o Acquire::Check-Valid-Until=false update; \
    DEBIAN_FRONTEND=noninteractive apt-get install --yes --no-install-recommends \
      ca-certificates \
      curl \
      gcc \
      libc6-dev \
      make \
      libpcre2-dev \
      zlib1g-dev

ARG NGINX_VERSION=1.31.5
ARG NGINX_SHA256=e951607d534836624bd36b6b45a71dbfb055237deae3738da6bbf3270dada279
ARG HEADERS_MORE_VERSION=0.40
ARG HEADERS_MORE_SHA256=c14cb5e6c998590c209efbf77bd7637ce2cab02332e4192756a8af5b26ba4284

RUN set -eux; \
    curl --proto '=https' --tlsv1.2 --fail --silent --show-error --location \
      "https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz" \
      --output /tmp/nginx.tar.gz; \
    echo "${NGINX_SHA256}  /tmp/nginx.tar.gz" | sha256sum --check --strict; \
    curl --proto '=https' --tlsv1.2 --fail --silent --show-error --location \
      "https://github.com/openresty/headers-more-nginx-module/archive/refs/tags/v${HEADERS_MORE_VERSION}.tar.gz" \
      --output /tmp/headers-more.tar.gz; \
    echo "${HEADERS_MORE_SHA256}  /tmp/headers-more.tar.gz" | sha256sum --check --strict; \
    tar --extract --gzip --file /tmp/nginx.tar.gz --directory /usr/src; \
    tar --extract --gzip --file /tmp/headers-more.tar.gz --directory /usr/src; \
    cd "/usr/src/nginx-${NGINX_VERSION}"; \
    ./configure \
      --with-compat \
      --add-dynamic-module="/usr/src/headers-more-nginx-module-${HEADERS_MORE_VERSION}"; \
    make -j2 modules; \
    strip --strip-unneeded objs/ngx_http_headers_more_filter_module.so; \
    touch --date="@${SOURCE_DATE_EPOCH}" objs/ngx_http_headers_more_filter_module.so; \
    test -s objs/ngx_http_headers_more_filter_module.so

FROM jonasal/nginx-certbot:6.2.0-nginx1.31.5@sha256:133f39cd8897f6987b56d1f6a182ec7ec4173490c10009a745a91dc94e0e9de4

ARG SOURCE_DATE_EPOCH
ARG SOURCE_URL=https://github.com/YannickLevadoux/loubepice-nginx-certbot
ARG SOURCE_REVISION=unknown

LABEL org.opencontainers.image.title="Loub'Epice Nginx Certbot" \
      org.opencontainers.image.description="Nginx and Certbot with the headers-more dynamic module" \
      org.opencontainers.image.version="1.2.0" \
      org.opencontainers.image.source="${SOURCE_URL}" \
      org.opencontainers.image.revision="${SOURCE_REVISION}" \
      org.opencontainers.image.base.name="docker.io/jonasal/nginx-certbot:6.2.0-nginx1.31.5" \
      org.opencontainers.image.base.digest="sha256:133f39cd8897f6987b56d1f6a182ec7ec4173490c10009a745a91dc94e0e9de4"

COPY requirements-runtime.txt /tmp/requirements-runtime.txt

RUN set -eux; \
    rm -f /etc/apt/sources.list.d/debian.sources; \
    printf '%s\n' \
      'Types: deb' \
      'URIs: https://snapshot.debian.org/archive/debian/20260905T000000Z' \
      'Suites: trixie trixie-updates' \
      'Components: main' \
      'Signed-By: /usr/share/keyrings/debian-archive-keyring.pgp' \
      '' \
      'Types: deb' \
      'URIs: https://snapshot.debian.org/archive/debian-security/20260905T000000Z' \
      'Suites: trixie-security' \
      'Components: main' \
      'Signed-By: /usr/share/keyrings/debian-archive-keyring.pgp' \
      > /etc/apt/sources.list.d/debian-snapshot.sources; \
    apt-get -o Acquire::Check-Valid-Until=false update; \
    DEBIAN_FRONTEND=noninteractive apt-get upgrade --yes --no-install-recommends; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/*; \
    python3 -m pip install \
      --break-system-packages \
      --disable-pip-version-check \
      --no-cache-dir \
      --require-hashes \
      --requirement /tmp/requirements-runtime.txt; \
    rm /tmp/requirements-runtime.txt

COPY --from=module-builder \
  /usr/src/nginx-1.31.5/objs/ngx_http_headers_more_filter_module.so \
  /usr/lib/nginx/modules/ngx_http_headers_more_filter_module.so

RUN set -eux; \
    test -s /usr/lib/nginx/modules/ngx_http_headers_more_filter_module.so; \
    if ! grep -Fqx 'load_module modules/ngx_http_headers_more_filter_module.so;' /etc/nginx/nginx.conf; then \
      { \
        printf '%s\n' 'load_module modules/ngx_http_headers_more_filter_module.so;'; \
        cat /etc/nginx/nginx.conf; \
      } > /tmp/nginx.conf; \
      mv /tmp/nginx.conf /etc/nginx/nginx.conf; \
    fi; \
    touch --date="@${SOURCE_DATE_EPOCH}" \
      /etc/nginx/nginx.conf \
      /usr/lib/nginx/modules/ngx_http_headers_more_filter_module.so; \
    nginx -t
