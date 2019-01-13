#!/bin/bash
set -e

hello_message () {
  echo "Installing Skadi Pack: Secure Networking"
  echo "This installation will do the following:"
  echo "  - Install and configure all prerequisites for mkcert to issue valid self-signed TLS certs"
  echo ""
  read -n 1 -r -s -p "Press any key to continue... or CTRL+C to exit (nothing has been installed)"
  echo ""
}

get_hostname () {
  # Ask for and validate domain name to use
  echo ""
  read -p "Please enter the FQDN, IP address, or routable hostname to use (cannot be blank): " hostinfo

  if [ -z "$hostinfo" ]; then
    echo "Warning: Hostname entered was Null or empty"
    echo "This is required. Exiting"
    exit
  fi
}

nginx_setup () {
  echo "Setting Up Nginx using '$hostinfo'"
  echo "Make the required directories and clean out existing nginx config files"
  sudo mkdir -p /etc/nginx/certs/letsencrypt
  sudo rm -rf /etc/nginx/conf.d/*

  echo "Customizing /etc/nginx/conf.d/skadi_TLS.conf"
  cat /opt/Skadi/Docker/nginx/skadi_TLS.conf | \
    sed "s/server_name  localhost/server_name $hostinfo localhost 127.0.0.1 \
    ::1/g" > /tmp/skadi_TLS.conf
  sudo sed -i "s/localhost.pem/$hostinfo.pem/g" /tmp/skadi_TLS.conf
  sudo sed -i "s/localhost.key.pem/$hostinfo.key.pem/g" /tmp/skadi_TLS.conf
  sudo mv /tmp/skadi_TLS.conf /etc/nginx/conf.d/
  sudo chown root:root /etc/nginx/conf.d/skadi_TLS.conf
  sudo chmod 644 /etc/nginx/conf.d/skadi_TLS.conf

  echo "Adding /etc/nginx/conf.d/ssl.conf"
  sudo cp /opt/Skadi/Docker/nginx/ssl.conf /etc/nginx/conf.d/ssl.conf
  sudo chown root:root /etc/nginx/conf.d/ssl.conf
  sudo chmod 644 /etc/nginx/conf.d/ssl.conf

  echo "Creating DHPARAM key"
  echo "This will take a while, the dots are the progress meter. If they are still being added, it's working"
  # Use the DHPARAM key and ECDH curve >= 256bit
  # Use this command to generate the key ''
  sudo openssl dhparam -out /etc/nginx/certs/dhparam.pem 4096
  echo "Nginx configuration for enabling TLS is complete"
  echo ""
}

mkcert_setup () {
  VER="v1.2.0"
  echo "Installing Mkcert"
  echo ""
  # Install and Configure Mkcert
  sudo apt update -y
  sudo apt-get install libnss3-tools -y
  sudo wget -O /usr/local/bin/mkcert "https://github.com/FiloSottile/mkcert/releases/download/$VER/mkcert-$VER-linux-amd64"
  sudo chmod +x /usr/local/bin/mkcert
  echo "Mkcert has been installed"
  echo ""

  echo "Creating Self Signed Certificates for 127.0.0.1 localhost $hostinfo ::1"
  echo ""
  sudo mkcert -install -cert-file /etc/nginx/certs/$hostinfo.pem -key-file /etc/nginx/certs/$hostinfo.key.pem 127.0.0.1 localhost $hostinfo ::1
  echo ""
  echo "Certificates were written to /etc/nginx/certs"
  echo ""
  echo "Restarting Nginx Docker"
  sudo docker restart nginx
  echo ""
}

fail2ban_setup () {
  echo "Installing Fail2Ban"
  sudo apt-get update && sudo apt-get install fail2ban -y
  echo ""
  echo "Configuring Fail2Ban to monitor 'sshd' and 'nginx-auth'"
  cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
  echo ""
  echo "Adding nginx-auth.jail to the local config file /etc/fail2ban/jail.local"
  cat /opt/Skadi/Docker/nginx/nginx-auth.jail | sudo tee -a /etc/fail2ban/jail.local
  sudo cp /opt/Skadi/Docker/nginx/nginx-auth.conf /etc/fail2ban/filter.d/nginx-auth.conf
  sudo chmod 644 /opt/Skadi/Docker/nginx/nginx-auth.conf
  sudo chmod 644
  sudo vim /etc/fail2ban/filter.d/nginx-auth.conf
  echo ""
  echo "Configuration Complet. Restarting Fail2Ban service"
  sudo service fail2ban restart
}

goodbye_message () {
  echo "Docker containers have been restarted and changes applied"
  echo ""
  echo "Mkcert is installed and configured to do the following:"
  echo "  - Install a ROOT CA to the local keystore"
  echo "  - Generate and apply certs for $hostinfo, localhost, 127.0.0.1, and ::1"
  echo ""
  echo "PLEASE NOTE: BROWSERS WILL STILL SHOW AS NOT SECURE EVEN THOUGH THEY ARE SERVING TLS ENCRYPTION"
  echo ""
  echo "For further info on self-signed certs please see: https://github.com/FiloSottile/mkcert"
}


############ MAIN PROGRAM #############

hello_message
get_hostname
nginx_setup
mkcert_setup
fail2ban_setup
goodbye_message
