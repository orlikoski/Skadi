#!/bin/bash

sudo docker run -it --rm --name certbot \
  -v /opt/Skadi/Docker/nginx/certs/letsencrypt:/etc/letsencrypt \
  -v /var/log/letsencrypt:/var/log/letsencrypt \
  -v /opt/Skadi/Docker/nginx/html/letsencrypt:/var/www/.well-known \
  certbot/certbot -t certonly \
  --agree-tos --renew-by-default \
  --webroot -w /var/www \
  -d localhost
