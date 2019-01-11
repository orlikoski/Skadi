#!b/in/bash

echo "Installing Skadi Pack: Secure Networking"
echo "This installation will do the following:"
echo "  - Update the Nginx reverse proxy for TimeSketch, Kibana, and Cerebro websites"
echo "  - Install and configure all prerequisits to install valid TLS/SSL certificates from Letsencrypt"
echo "  - Change the default passwords for TimeSketch, Kibana and Cerebro (created dynamically at run time)"
echo "  - Enable TLS/SSL encryption using Letsencrypt"
echo ""
echo "In order to continue a publicly accessable FQDN (such as 'mydomain.com') is required"
echo "The Kibana, Cerebro, and TimeSketch websites will be configured to use that FQDN"
echo "This cannot be left blank for the TLS certificates to work"
echo ""
echo ""
echo "Example Domain: 'mydomain.com'"
echo "Results in the following: "
echo "   - 'mydomain.com'"
echo "   - 'mydomain.com/kibana'"
echo "   - 'mydomain.com/cerebro'"
echo ""
echo "All of this can be changed in the following file:"
echo "   - /etc/nginx/sites-available/default"
echo ""
echo ""
echo "All usernames and passwords are made dynamically at run time"
echo "These are displayed at the end of the script (record them for use)"
echo ""
echo "*********** WARNING ***********"
echo "This script was built and tested to work on Skadi 2018.2"
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
read -p "Please enter the FQDN, IP address, or routable hostname to use (cannot be blank): " new_domain

if [ -z "$new_domain" ]; then
  echo "Warning: Hostname entered was Null or empty"
  echo "This is required. Exiting"
  exit
fi


# Add domain name (if changed) and enable basic auth
if [[ ! -z "$new_domain" ]]; then
  echo "Replacing existing server name with '$new_domain'"
  sudo sed -i "s/server_name .*\;/server_name $new_domain\;/g" /etc/nginx/sites-available/default
fi

# Install and Configure Mkcert

sudo apt update -y
sudo apt-get install libnss3-tools -y
export mkcert VER="V.1.2.0"
sudo wget -O /usr/local/bin mkcert https://github.com/FiloSottile/mkcert/releases/download/${VER}/mkcert-${VER}-linux-amd64
sudo chmod +x /usr/local/bin/mkcert

# Install and Configure Letsencrypt
sudo apt update -y
sudo apt install software-properties-common -y
sudo add-apt-repository ppa:certbot/certbot -y
sudo apt update -y
sudo apt install python-certbot-nginx -y
sudo apt autoremove -y
echo ""
echo ""
echo ""
echo ""
echo ""
echo "Nginx reverse proxy update is complete with the following:"
echo "Hostname: '$new_domain'"
echo "The following are reverse proxied with authentication: "
echo ""
echo "  TimeSketch:"
echo "   - 'http://$new_domain'"
echo ""
echo "  Kibana:"
echo "   - 'http://$new_domain/kibana'"
echo "     - Username: $k_user"
echo "     - Password: $k_pass"
echo ""
echo "  Cerebro"
echo "   - 'http://$new_domain/cerebro'"
echo "     - Username: $c_user"
echo "     - Password: $c_pass"
echo ""
echo ""
echo ""
echo ""
echo "*********** WARNING ***********"
echo "The next step requires a publicly accessable FQDN with working DNS"
echo "If there is an issue with the FQDN, IP address, or routable hostname please stop now"
echo " - This can be changed in '/etc/nginx/sites-available/default'"
echo " - Change the line that start with 'server_name' to the correct name before continuing"
echo ""
echo "If there are any issues it is best to stop now and, when it is configured corrctly, run 'sudo certbot --nginx' manually"
echo "*********** WARNING ***********"
echo ""
echo ""
read -n 1 -r -s -p "If it is configured correctly; Press any key to continue... or CTRL+C to exit"
echo ""
echo ""
sudo certbot --nginx
