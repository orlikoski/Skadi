#!/bin/bash
set -e

hello_message () {
  echo "Installing Skadi Pack: Letsencrypt"
  echo "This installation will do the following:"
  echo "  - Use the certbot/certbot docker container to install valid TLS certs"
  echo ""
  echo "Please note that a FQDN (example: myhost.mydomain.com) with working DNS"
  echo "is required in order for Letsencrypt to access it via the Internet and complete the installation."
  echo "If that is not setup, quit now and restart script when it is working..."
  read -n 1 -r -s -p "Press any key to continue... or CTRL+C to exit (nothing has been installed)"
  echo ""
}

get_hostname () {
  # Ask for and validate FQDN name to use
  echo ""
  read -p "Please enter the FQDN (example: myhost.mydomain.com) to use (cannot be blank): " hostinfo

  if [ -z "$hostinfo" ]; then
    echo "Warning: Hostname entered was Null or empty"
    echo "This is required. Exiting"
    exit
  fi
}

nginx_disable () {
  echo "Stopping Nginx Docker"
  sudo docker stop nginx
  echo ""
}

nginx_enable () {
  echo "Staring nginx container"
  sudo docker start nginx
}

nginx_update_hostname () {
  sudo rm -rf /tmp/skadi_TLS.conf
  echo "Updating the /etc/nginx/conf.d/skadi_TLS.conf to use $hostinfo"
  cp /etc/nginx/conf.d/skadi_TLS.conf /tmp/skadi_TLS.conf
  sudo sed -i -E "s@server_name .*;@server_name  $hostinfo;@g" /tmp/skadi_TLS.conf
  sudo cp /tmp/skadi_TLS.conf /etc/nginx/conf.d/skadi_TLS.conf
  sudo chmod 644 /etc/nginx/conf.d/skadi_TLS.conf
}

nginx_update_certs () {
echo "Updating the /etc/nginx/conf.d/skadi_TLS.conf to use letsencrypt certificates"
sudo sed -i "s@ssl_certificate       /etc/nginx/certs/.*.pem@ssl_certificate       /etc/nginx/certs/letsencrypt/live/$hostinfo/fullchain.pem@g" /tmp/skadi_TLS.conf
sudo sed -i "s@ssl_certificate_key   /etc/nginx/certs/.*.key.pem@ssl_certificate_key   /etc/nginx/certs/letsencrypt/live/$hostinfo/privkey.pem@g" /tmp/skadi_TLS.conf
sudo cp /tmp/skadi_TLS.conf /etc/nginx/conf.d/skadi_TLS.conf
sudo chmod 644 /etc/nginx/conf.d/skadi_TLS.conf
}

enable_ocsp () {
sudo rm -rf /tmp/ssl.conf
echo "Updating the /etc/nginx/conf.d/ssl.conf to enable OCSP protection"
cp /etc/nginx/conf.d/ssl.conf /tmp/ssl.conf
sudo sed -i "s@# ssl_stapling on;@ssl_stapling on;@g" /tmp/ssl.conf
sudo sed -i "s@# ssl_stapling_verify on;@ssl_stapling_verify on;@g" /tmp/ssl.conf
sudo sed -i "s@# ssl_trusted_certificate /etc/nginx/certs/letsencrypt/live/localhost/chain.pem;@ssl_trusted_certificate /etc/nginx/certs/letsencrypt/live/$hostinfo/chain.pem;@g" /tmp/ssl.conf
sudo sed -i "s@# resolver 8.8.8.8 8.8.4.4 valid=300s;@resolver 8.8.8.8 8.8.4.4 valid=300s;@g" /tmp/ssl.conf
sudo sed -i "s@# resolver_timeout 5s;@resolver_timeout 5s;@g" /tmp/ssl.conf
sudo cp /tmp/ssl.conf /etc/nginx/conf.d/ssl.conf
sudo chmod 644 /etc/nginx/conf.d/ssl.conf
}

setup_certbot () {
  cp /opt/Skadi/scripts/certs.sh /tmp/certs
  sudo sed -i "s@localhost@$hostinfo@g" /tmp/certs
  sudo mv /tmp/certs /etc/cron.monthly/
  sudo chmod 755 /etc/cron.monthly/certs
  sudo bash /etc/cron.monthly/certs
}

goodbye_message () {
  echo "Nginx Docker container has been restarted and changes applied"
  echo ""
  echo "Letsencrypt has been used to install valid TLS certificates"
  echo "  - Certificates are stored in /etc/nginx/certs/letsencrypt/live/$hostinfo/"
  echo ""
  echo "For further info on Letsencrypt certs please see: https://letsencrypt.org/"
  echo ""
  echo "Visit https://$hostinfo to verify installation"
}

############ MAIN PROGRAM #############
hello_message
get_hostname
nginx_disable
nginx_update_hostname
nginx_enable
setup_certbot
nginx_disable
nginx_update_certs
enable_ocsp
nginx_enable
goodbye_message
