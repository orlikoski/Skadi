#!/bin/bash
set -e

echo "Installing Skadi Pack: Secure Networking"
echo "This installation will do the following:"
echo "  - Install and configure all prerequisites for mkcert to issue valid self-signed TLS certs"
echo ""
read -n 1 -r -s -p "Press any key to continue... or CTRL+C to exit (nothing has been installed)"
echo ""

# Ask for and validate domain name to use
echo ""
read -p "Please enter the FQDN, IP address, or routable hostname to use (cannot be blank): " hostinfo

if [ -z "$hostinfo" ]; then
  echo "Warning: Hostname entered was Null or empty"
  echo "This is required. Exiting"
  exit
fi

# Add domain name (if changed) and enable basic auth
if [[ ! -z "$hostinfo" ]]; then
  echo "Replacing existing server name with '$hostinfo'"

  # Set up Environment for nginx TLS config
  sudo mkdir -p /etc/nginx/certs/
  sudo rm -rf /etc/nginx/conf.d/*
  cat /opt/Skadi/Docker/nginx/skadi_TLS.conf | sed "s/server_name  localhost/server_name $hostinfo localhost 127.0.0.1 ::1/g" > /tmp/skadi_TLS.conf
  sudo sed -i "s/localhost.pem/$hostinfo.pem/g" /tmp/skadi_TLS.conf
  sudo sed -i "s/localhost.key.pem/$hostinfo.key.pem/g" /tmp/skadi_TLS.conf
  sudo mv /tmp/skadi_TLS.conf /etc/nginx/conf.d/
  sudo chown root:root /etc/nginx/conf.d/skadi_TLS.conf
  sudo chmod 644 /etc/nginx/conf.d/skadi_TLS.conf
fi
echo "Nginx configuration for enabling TLS has been updated"
echo ""
echo "Installing and configuring Mkcert"
echo ""
# Install and Configure Mkcert
sudo apt update -y
sudo apt-get install libnss3-tools -y
VER="v1.2.0"
sudo wget -O /usr/local/bin/mkcert "https://github.com/FiloSottile/mkcert/releases/download/$VER/mkcert-$VER-linux-amd64"
sudo chmod +x /usr/local/bin/mkcert
sudo mkcert -install -cert-file /etc/nginx/certs/$hostinfo.pem -key-file /etc/nginx/certs/$hostinfo.key.pem 127.0.0.1 localhost $hostinfo ::1
echo ""
echo "Mkcert has been installed and certs were written to /etc/nginx/certs"
echo ""
echo "Restarting Nginx Docker"
# Restarting docker
cd /opt/Skadi/Docker
sudo docker-compose up -d
echo ""
echo "Docker containers have been restarted and changes applied"
echo ""
echo "Mkcert is installed and configured to do the following:"
echo "  - Install a ROOT CA to the local keystore"
echo "  - Generate and apply certs for $hostinfo, localhost, 127.0.0.1, and ::1"
echo ""
echo "PLEASE NOTE: BROWSERS WILL STILL SHOW AS NOT SECURE EVEN THOUGH THEY ARE SERVING TLS ENCRYPTION"
echo ""
echo "For further info on self-signed certs please see: https://github.com/FiloSottile/mkcert"
