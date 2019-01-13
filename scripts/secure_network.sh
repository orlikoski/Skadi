#!b/in/bash

echo "Installing Skadi Pack: Secure Networking"
echo "This installation will do the following:"
echo "  - Install and configure all prerequisites for mkcert to issue valid self-signed TLS certs"
echo ""
echo "Mkcert is installed and configured to do the following:"
echo "  - Install to local keystore"
echo "  - Generate self signed TLS certs"
echo "  - Write these certs to nginx config to serve nginx with TLS encryption"
echo "" 
echo "PLEASE NOTE: BROWSERS WILL STILL SHOW AS NOT SECURE EVEN THOUGH THEY ARE SERVING TLS ENCRYPTION"
echo ""
echo "For further info on self-signed certs please see: https://github.com/FiloSottile/mkcert"
echo ""
echo "All usernames and passwords are made dynamically at run time"
echo "These are displayed at the end of the script (record them for use)"
echo ""
echo "*********** WARNING ***********"
echo "This script was built and tested to work on Skadi 2019.1"
echo "It is not possible to predict the results of using it on any other platform"
echo "root or sudo privileges are required for this installation"
echo "*********** WARNING ***********"
echo ""
read -n 1 -r -s -p "Press any key to continue... or CTRL+C to exit (nothing has been installed)"
echo ""
echo ""

# Ask for and validate domain name to use
echo ""
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
echo ""
echo ""
echo ""
echo ""
echo ""
# Install and Configure Mkcert
sudo apt update -y
sudo apt-get install libnss3-tools -y
VER="v1.2.0"
sudo wget -O /usr/local/bin/mkcert "https://github.com/FiloSottile/mkcert/releases/download/$VER/mkcert-$VER-linux-amd64"
sudo chmod +x /usr/local/bin/mkcert
sudo mkcert -install -cert-file /etc/nginx/certs/$hostinfo.pem -key-file /etc/nginx/certs/$hostinfo.key.pem 127.0.0.1 localhost $hostinfo ::1
echo ""
echo ""
echo ""
echo ""
echo ""
echo "Mkcert has been installed and written generated certs to nginx certs directory"
echo ""
echo ""
echo ""
echo ""
echo ""
echo "Nginx reverse proxy update is complete with the following:"
echo "Hostname: '$hostinfo'"
echo "The following are reverse proxied with authentication: "
echo ""
echo "  TimeSketch:"
echo "   - 'http://$hostinfo'"
echo ""
echo "  Kibana:"
echo "   - 'http://$hostinfo/kibana'"
echo "     - Username: $k_user"
echo "     - Password: $k_pass"
echo ""
echo "  Cerebro"
echo "   - 'http://$hostinfo/cerebro'"
echo "     - Username: $c_user"
echo "     - Password: $c_pass"
echo ""
echo ""
echo ""
echo ""
echo ""
read -n 1 -r -s -p "If it is configured correctly; Press any key to continue... or CTRL+C to exit"
echo ""
echo ""
echo ""
echo ""
echo ""
# Restarting docker
cd /opt/Skadi/Docker
sudo docker-compose up -d
echo ""
echo ""
echo ""
echo ""
echo ""
echo "Docker containers have been brought back up to take the above changes"
