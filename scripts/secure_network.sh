#!/bin/bash 

echo "This script is going to disable IPv6, install, configure, and enable the Nginx reverse proxy and configure letsencrypt for valid certificats."
echo "In order to continue a domain name needs to provided and the Kibana, Cerebro, and TimeSketch websites will be setup as sub-domains"
echo "Example Domain: 'mydomain.com'"
echo "Results in the following: "
echo "   - 'kibana.mydomain.com'"
echo "   - 'cerebro.mydomain.com'"
echo "   - 'timesketch.mydomain.com'"
echo
echo "All of this can be changed in the following files:"
echo "   - /etc/nginx/sites-available/kibana"
echo "   - /etc/nginx/sites-available/cerebro"
echo "   - /etc/nginx/sites-available/timesketch"

# Ask for and validate domain name to use
echo ""
echo ""
read -p "Please enter the domain name to use: " new_domain

if [ -z "$new_domain" ]; then
        echo "ERROR: Domain cannot be empty or Null. Exiting"
        exit 1
fi

# Disable IPv6
echo "net.ipv6.conf.all.disable_ipv6 = 1" | sudo tee -a /etc/sysctl.d/99-sysctl.conf
echo "net.ipv6.conf.default.disable_ipv6 = 1" | sudo tee -a /etc/sysctl.d/99-sysctl.conf
echo "net.ipv6.conf.lo.disable_ipv6 = 1" | sudo tee -a /etc/sysctl.d/99-sysctl.conf
sudo sysctl -p

# Install Nginx and web utils
sudo apt install nginx apache2-utils -y
sudo ufw allow 'Nginx Full'
sudo ufw allow 'OpenSSH'
sudo ufw --force enable

# Configure Nginx for Kibana, Cerebro, and TimeSketch
old_domain="localdomain.com"

cerebro_conf="c2VydmVyIHsKICBsaXN0ZW4gODA7CiAgICBzZXJ2ZXJfbmFtZSBjZXJlYnJvLmxvY2FsZG9tYWluLmNvbSB3d3cuY2VyZWJyby5sb2NhbGRvbWFpbi5jb207CgogIGVycm9yX2xvZyAgIC92YXIvbG9nL25naW54L2NlcmVicm8uZXJyb3IubG9nOwogIGFjY2Vzc19sb2cgIC92YXIvbG9nL25naW54L2NlcmVicm8uYWNjZXNzLmxvZzsKCiAgbG9jYXRpb24gLyB7CiAgICBwcm94eV9wYXNzIGh0dHA6Ly9sb2NhbGhvc3Q6OTAwMDsKICB9Cn0K"
echo $cerebro_conf |base64 -d | sudo tee /etc/nginx/sites-available/cerebro
sudo sed -i "s/$old_domain/$new_domain/g" /etc/nginx/sites-available/cerebro
sudo ln -s /etc/nginx/sites-available/cerebro /etc/nginx/sites-enabled/cerebro

timeksetch_conf="c2VydmVyIHsKICBsaXN0ZW4gODA7CiAgICBzZXJ2ZXJfbmFtZSB0aW1lc2tldGNoLmxvY2FsZG9tYWluLmNvbSB3d3cudGltZXNrZXRjaC5sb2NhbGRvbWFpbi5jb207CgogIGVycm9yX2xvZyAgIC92YXIvbG9nL25naW54L3RpbWVza2V0Y2guZXJyb3IubG9nOwogIGFjY2Vzc19sb2cgIC92YXIvbG9nL25naW54L3RpbWVza2V0Y2guYWNjZXNzLmxvZzsKCiAgbG9jYXRpb24gLyB7CiAgICBwcm94eV9wYXNzIGh0dHA6Ly9sb2NhbGhvc3Q6NTAwMDsKICB9Cn0K"
echo $timeksetch_conf |base64 -d | sudo tee /etc/nginx/sites-available/timesketch
sudo sed -i "s@$old_domain@$new_domain@g" /etc/nginx/sites-available/timesketch
sudo ln -s /etc/nginx/sites-available/kibana /etc/nginx/sites-enabled/timesketch

kibana_conf="c2VydmVyIHsKICBsaXN0ZW4gODA7CiAgICBzZXJ2ZXJfbmFtZSBraWJhbmEubG9jYWxkb21haW4uY29tIHd3dy5raWJhbmEubG9jYWxkb21haW4uY29tOwoKICBlcnJvcl9sb2cgICAvdmFyL2xvZy9uZ2lueC9raWJhbmEuZXJyb3IubG9nOwogIGFjY2Vzc19sb2cgIC92YXIvbG9nL25naW54L2tpYmFuYS5hY2Nlc3MubG9nOwoKICBsb2NhdGlvbiAvIHsKICAgIHByb3h5X3Bhc3MgaHR0cDovL2xvY2FsaG9zdDo1NjAxOwogIH0KfQo="
echo $kibana_conf |base64 -d | sudo tee /etc/nginx/sites-available/kibana
sudo sed -i "s@$old_domain@$new_domain@g" /etc/nginx/sites-available/kibana
sudo ln -s /etc/nginx/sites-available/timesketch /etc/nginx/sites-enabled/kibana

sudo systemctl restart nginx
sudo systemctl enable nginx

# Install and Configure Letsencrypt
sudo apt update -y
sudo apt install software-properties-common -y
sudo add-apt-repository ppa:certbot/certbot -y
sudo apt update -y
sudo apt install python-certbot-nginx -y

echo ""
echo ""
echo ""
echo ""
echo ""
echo "Nginx setup complete with the following:"
echo "Domain: '$new_domain'"
echo "The following are now being reverse proxied at: "
echo "   - 'http://kibana.$new_domain'"
echo "   - 'http://cerebro.$new_domain'"
echo "   - 'http://timesketch.$new_domain'"
echo ""
echo "WARNING!!! Encryption is not enabled and it is strongly recommended to enable it"
echo ""
echo "Letsencrypt is installed and able to encrypt these sites. It is not enabled by default"
echo "To start the Letsencrypt setup process type the following and follow the installation prompts:"
echo "sudo certbot --nginx"
