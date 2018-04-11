#!/bin/bash 

echo "Installing Skadi Pack: Secure Networking"
echo "This installation will do the following:"
echo "  - Disable IPv6"
echo "  - Install and configure Nginx reverse proxy for TimeSketch, Kibana, and Cerebro websites"
echo "  - Install and configure all prerequisits, and provide single command, required to install valid TLS/SSL certificates from Letsencrypt"
echo ""
echo "In order to continue a domain name needs to provided and the Kibana, Cerebro, and TimeSketch websites will be setup as sub-domains"
echo "For testing and home/student use it is recommended to use a 'xip.io' domain. Read more about it here: http://xip.io/"
echo ""
echo "Example Domain: 'mydomain.com'"
echo "Results in the following: "
echo "   - 'kibana.mydomain.com'"
echo "   - 'cerebro.mydomain.com'"
echo "   - 'timesketch.mydomain.com'"
echo ""
echo "All of this can be changed in the following files:"
echo "   - /etc/nginx/sites-available/kibana"
echo "   - /etc/nginx/sites-available/cerebro"
echo "   - /etc/nginx/sites-available/timesketch"
echo ""
echo ""
echo "All usernames and passwords are made dynamically at run time"
echo "These are displayed at the end of the script (record them for use)"
echo ""
echo "*********** WARNING ***********"
echo "root or sudo privileges are required for this installation"
echo "*********** WARNING ***********"
echo ""
read -n 1 -r -s -p "Press any key to continue... or CTRL+C to exit (nothing has been installed)"
echo ""
echo ""

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
old_domain="10.1.0.43.xip.io"

# Cerebro config and basic_auth user creation
cerebro_conf="c2VydmVyIHsKICBsaXN0ZW4gODA7CiAgICBzZXJ2ZXJfbmFtZSBjZXJlYnJvLjEwLjEuMC40My54aXAuaW8gd3d3LmNlcmVicm8uMTAuMS4wLjQzLnhpcC5pbzsKCiAgZXJyb3JfbG9nICAgL3Zhci9sb2cvbmdpbngvY2VyZWJyby5lcnJvci5sb2c7CiAgYWNjZXNzX2xvZyAgL3Zhci9sb2cvbmdpbngvY2VyZWJyby5hY2Nlc3MubG9nOwoKCiAgbG9jYXRpb24gLyB7CiAgICBwcm94eV9wYXNzIGh0dHA6Ly9sb2NhbGhvc3Q6OTAwMDsKICAgIGF1dGhfYmFzaWMgIkNlcmVicm8gTG9naW4iOwogICAgYXV0aF9iYXNpY191c2VyX2ZpbGUgL2V0Yy9uZ2lueC8uY2VyZWJyb19hdXRoOwogIH0KfQo="
c_user="ceruser_$(openssl rand -base64 3)"
c_pass=$(openssl rand -base64 32)
echo $c_pass | sudo htpasswd -i -c /etc/nginx/.cerebro_auth $c_user

echo $cerebro_conf |base64 -d | sudo tee /etc/nginx/sites-available/cerebro
sudo sed -i "s/$old_domain/$new_domain/g" /etc/nginx/sites-available/cerebro
sudo ln -s /etc/nginx/sites-available/cerebro /etc/nginx/sites-enabled/cerebro

# TimeSketch config and basic_auth user creation
timeksetch_conf="c2VydmVyIHsKICBsaXN0ZW4gODA7CiAgICBzZXJ2ZXJfbmFtZSB0aW1lc2tldGNoLjEwLjEuMC40My54aXAuaW8gd3d3LnRpbWVza2V0Y2guMTAuMS4wLjQzLnhpcC5pbzsKCiAgZXJyb3JfbG9nICAgL3Zhci9sb2cvbmdpbngvdGltZXNrZXRjaC5lcnJvci5sb2c7CiAgYWNjZXNzX2xvZyAgL3Zhci9sb2cvbmdpbngvdGltZXNrZXRjaC5hY2Nlc3MubG9nOwoKICBsb2NhdGlvbiAvIHsKICAgIHByb3h5X3Bhc3MgaHR0cDovL2xvY2FsaG9zdDo1MDAwOwogICAgYXV0aF9iYXNpYyAiVGltZVNrZXRjaCBMb2dpbiI7CiAgICBhdXRoX2Jhc2ljX3VzZXJfZmlsZSAvZXRjL25naW54Ly50aW1lc2tldGNoX2F1dGg7CiAgfQp9Cg=="
t_user="tsuser_$(openssl rand -base64 3)"
t_pass=$(openssl rand -base64 32)
echo $t_pass | sudo htpasswd -i -c /etc/nginx/.timesketch_auth $t_user

echo $timeksetch_conf |base64 -d | sudo tee /etc/nginx/sites-available/timesketch
sudo sed -i "s@$old_domain@$new_domain@g" /etc/nginx/sites-available/timesketch
sudo ln -s /etc/nginx/sites-available/kibana /etc/nginx/sites-enabled/timesketch

# Kibana config and basic_auth user creation
kibana_conf="c2VydmVyIHsKICBsaXN0ZW4gODA7CiAgICBzZXJ2ZXJfbmFtZSBraWJhbmEuMTAuMS4wLjQzLnhpcC5pbyB3d3cua2liYW5hLjEwLjEuMC40My54aXAuaW87CgogIGVycm9yX2xvZyAgIC92YXIvbG9nL25naW54L2tpYmFuYS5lcnJvci5sb2c7CiAgYWNjZXNzX2xvZyAgL3Zhci9sb2cvbmdpbngva2liYW5hLmFjY2Vzcy5sb2c7CgogIGxvY2F0aW9uIC8gewogICAgcHJveHlfcGFzcyBodHRwOi8vbG9jYWxob3N0OjU2MDE7CiAgICBhdXRoX2Jhc2ljICJLaWJhbmEgTG9naW4iOwogICAgYXV0aF9iYXNpY191c2VyX2ZpbGUgL2V0Yy9uZ2lueC8ua2liYW5hX2F1dGg7CiAgfQp9Cg=="
k_user="kibuser_$(openssl rand -base64 3)"
k_pass=$(openssl rand -base64 32)
echo $k_pass | sudo htpasswd -i -c /etc/nginx/.kibana_auth $k_user

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
echo "Nginx reverse proxy setup is complete with the following:"
echo "Domain: '$new_domain'"
echo "The following are now being reverse proxied with authentication at: "
echo "   - 'http://kibana.$new_domain'"
echo "       - Username: $k_user"
echo "       - Password: $k_pass"
echo ""
echo "   - 'http://cerebro.$new_domain'"
echo "       - Username: $c_user"
echo "       - Password: $c_pass"
echo ""
echo "   - 'http://timesketch.$new_domain'"
echo "       - Username: $t_user"
echo "       - Password: $t_pass"
echo ""
echo "WARNING!!! Encryption is not enabled and it is strongly recommended to enable it"
echo ""
echo ""
echo "Letsencrypt is installed and able to encrypt these sites. It is not enabled by default"
echo "To start the Letsencrypt setup process type the following and follow the installation prompts:"
echo "sudo certbot --nginx"
