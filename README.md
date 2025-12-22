https://github.com/JonasAlfredsson/docker-nginx-certbot/issues/154

Based on jonasal/nginx-certbot project, version 4.3.0-nginx1.25.2 (Almost fully autonomous Nginx server using Let's Encrypt to get SSL certificates)
This image contains
- header-more module : get header-more module version 


Image pushed on docker hub:
https://hub.docker.com/repository/docker/yannick7fr/nginx-certbot-custom/general

image name : `nginx-certbot-custom:1.1`

Commands :

- docker build -t yannick7fr/nginx-certbot-custom:1.1 .
- docker push yannick7fr/nginx-certbot-custom:1.1