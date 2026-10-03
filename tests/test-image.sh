#!/usr/bin/env bash
set -euo pipefail

image_ref=${1:-loubepice-nginx-certbot:test}
expected_version=${2:-dev}
repository_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
test_root=$(mktemp -d "${TMPDIR:-/tmp}/nginx-certbot-test.XXXXXX")
container_name="loubepice-nginx-certbot-test-$$"

cleanup() {
  docker rm --force "$container_name" >/dev/null 2>&1 || true
  rm -rf -- "${test_root:?}"
}
trap cleanup EXIT

docker run --rm --platform linux/amd64 --entrypoint nginx "$image_ref" -t

nginx_version=$(docker run --rm --platform linux/amd64 --entrypoint nginx \
  "$image_ref" -v 2>&1)
certbot_version=$(docker run --rm --platform linux/amd64 --entrypoint certbot \
  "$image_ref" --version 2>&1)
test "$nginx_version" = 'nginx version: nginx/1.31.6'
test "$certbot_version" = 'certbot 5.8.0'
docker run --rm --platform linux/amd64 --entrypoint python3 \
  "$image_ref" -m pip check

docker run --rm --platform linux/amd64 --entrypoint sh "$image_ref" -c \
  'test -s /usr/lib/nginx/modules/ngx_http_headers_more_filter_module.so &&
   nginx -T 2>&1 | grep -Fq "load_module modules/ngx_http_headers_more_filter_module.so;"'

source_label=$(docker image inspect --format \
  '{{ index .Config.Labels "org.opencontainers.image.source" }}' "$image_ref")
revision_label=$(docker image inspect --format \
  '{{ index .Config.Labels "org.opencontainers.image.revision" }}' "$image_ref")
version_label=$(docker image inspect --format \
  '{{ index .Config.Labels "org.opencontainers.image.version" }}' "$image_ref")
base_name_label=$(docker image inspect --format \
  '{{ index .Config.Labels "org.opencontainers.image.base.name" }}' "$image_ref")
base_digest_label=$(docker image inspect --format \
  '{{ index .Config.Labels "org.opencontainers.image.base.digest" }}' "$image_ref")
test "$source_label" = 'https://github.com/YannickLevadoux/loubepice-nginx-certbot'
test -n "$revision_label"
test "$version_label" = "$expected_version"
test "$base_name_label" = 'docker.io/jonasal/nginx-certbot:6.2.0-nginx1.31.6'
test "$base_digest_label" = \
  'sha256:ccd7b8b4fbb538a493012b52edfddeb51cbfec974ef7f8cd341894c5dae02925'

openssl req -x509 -newkey rsa:2048 -nodes -days 1 \
  -subj '/CN=localhost' \
  -keyout "$test_root/key.pem" \
  -out "$test_root/cert.pem" >/dev/null 2>&1

docker run --detach --rm \
  --platform linux/amd64 \
  --name "$container_name" \
  --entrypoint nginx \
  --volume "$repository_root/tests/nginx.conf:/etc/nginx/nginx.conf:ro" \
  --volume "$test_root:/etc/nginx/test-certs:ro" \
  "$image_ref" -g 'daemon off;' >/dev/null

for attempt in $(seq 1 30); do
  if docker exec "$container_name" python3 -c \
    "import urllib.request; r=urllib.request.urlopen('http://127.0.0.1:8080/test', timeout=5); assert r.status == 200; assert r.headers['X-Headers-More'] == 'loaded'"; then
    break
  fi
  if [[ "$attempt" -eq 30 ]]; then
    docker logs "$container_name"
    echo 'The local HTTP test did not become ready.' >&2
    exit 1
  fi
  sleep 1
done

# Exact command used by the production Compose healthcheck contract (#80).
docker exec "$container_name" sh -c \
  'nginx -t -q && python3 -c "import ssl, urllib.request; urllib.request.urlopen('\''https://127.0.0.1/50x.html'\'', context=ssl._create_unverified_context(), timeout=5)"'

echo 'versions, labels, Python dependencies, nginx -t, headers-more, local HTTP response and expected healthcheck: OK'
