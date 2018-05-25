#!/bin/bash
echo "Installing Skadi Pack: Secure Networking"
echo "This installation will do the following:"
echo "  - Disable IPv6"
echo "  - Install and configure Nginx reverse proxy for TimeSketch, Kibana, and Cerebro websites"
echo "  - Install and configure all prerequisits to install valid TLS/SSL certificates from Letsencrypt"
echo "  - Provide single command required to enable TLS/SSL encryption on all three websites"
echo ""
echo "In order to continue a hostname needs to provided and the Kibana, Cerebro, and TimeSketch websites will be setup as sub-domains"
echo "This can be left blank for local use."
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
echo "root or sudo privileges are required for this installation"
echo "*********** WARNING ***********"
echo ""
read -n 1 -r -s -p "Press any key to continue... or CTRL+C to exit (nothing has been installed)"
echo ""
echo ""
# Disable IPv6
echo "net.ipv6.conf.all.disable_ipv6 = 1" | sudo tee -a /etc/sysctl.d/99-sysctl.conf
echo "net.ipv6.conf.default.disable_ipv6 = 1" | sudo tee -a /etc/sysctl.d/99-sysctl.conf
echo "net.ipv6.conf.lo.disable_ipv6 = 1" | sudo tee -a /etc/sysctl.d/99-sysctl.conf
sudo sysctl -p

# Ask for and validate domain name to use
echo ""
echo ""
read -p "Please enter the hostname name to use (leave blank if not using a FQDN or routable hostname): " new_domain

if [ -z "$new_domain" ]; then
  echo "Warning: Domain entered was Null or empty"
  echo "Using '_' for server name which will listen to all incoming requests"
  echo "The server name can be changed later in /etc/nginx/sites-available/default"
fi

# Install and configure gunicorn
sudo pip2 install gunicorn
sudo systemctl stop timesketch
timesketch_service="W1VuaXRdCkRlc2NyaXB0aW9uPVRpbWVTa2V0Y2ggU2VydmljZQpBZnRlcj1uZXR3b3JrLnRhcmdldAoKW1NlcnZpY2VdClVzZXI9dGltZXNrZXRjaApHcm91cD10aW1lc2tldGNoCkV4ZWNTdGFydD0vdXNyL2xvY2FsL2Jpbi9ndW5pY29ybiAtLXdvcmtlcnMgNCAtLWJpbmQgMTI3LjAuMC4xOjUwMDAgdGltZXNrZXRjaC53c2dpCgpbSW5zdGFsbF0KV2FudGVkQnk9bXVsdGktdXNlci50YXJnZXQK"
echo $timesketch_service |base64 -d | sudo tee /etc/systemd/system/timesketch.service
sudo systemctl daemon-reload
sudo systemctl restart timesketch.service




# Update Kibana to work with forwarding
sudo systemctl stop kibana
sudo sed -i "s@\#server.basePath: \"\"@server.basePath: \"/kibana\"@g" /etc/kibana/kibana.yml
sudo systemctl start kibana

# Install Nginx and web utils
sudo apt install nginx apache2-utils -y
sudo ufw allow 'Nginx Full'
sudo ufw allow 'OpenSSH'
sudo ufw --force enable

# Configure Nginx for Kibana, Cerebro, and TimeSketch
nginx_conf="c2VydmVyIHsKICBsaXN0ZW4gODA7CiAgc2VydmVyX25hbWUgXzsKICBjbGllbnRfbWF4X2JvZHlfc2l6ZSA3NU07CiAgcHJveHlfY29ubmVjdF90aW1lb3V0IDkwMHM7CiAgcHJveHlfcmVhZF90aW1lb3V0IDkwMHM7CiAgcm9vdCAgICAgICAgIC91c3Ivc2hhcmUvbmdpbngvaHRtbDsKICBlcnJvcl9wYWdlIDQwNCAvNDA0Lmh0bWw7CiAgICBsb2NhdGlvbiA9IC80MDQuaHRtbCB7fQogIGVycm9yX3BhZ2UgNTAwIDUwMiA1MDMgNTA0IC81MHguaHRtbDsKICAgIGxvY2F0aW9uID0gLzUweC5odG1sIHt9CgogIGVycm9yX2xvZyAgIC92YXIvbG9nL25naW54L2Vycm9yLmxvZzsKICBhY2Nlc3NfbG9nICAvdmFyL2xvZy9uZ2lueC9hY2Nlc3MubG9nOwoKICBsb2NhdGlvbiAvIHsKICAgIHByb3h5X3Bhc3MgaHR0cDovL2xvY2FsaG9zdDo1MDAwOwogICAgcHJveHlfaHR0cF92ZXJzaW9uIDEuMTsKICAgIHByb3h5X3NldF9oZWFkZXIgVXBncmFkZSAkaHR0cF91cGdyYWRlOwogICAgcHJveHlfc2V0X2hlYWRlciBDb25uZWN0aW9uICd1cGdyYWRlJzsKICAgIHByb3h5X3NldF9oZWFkZXIgSG9zdCAkaG9zdDsKICAgIHByb3h5X2NhY2hlX2J5cGFzcyAkaHR0cF91cGdyYWRlOwogICAgc3ViX2ZpbHRlciAnTG9nb3V0PC9hPicgJ0xvZ291dDwvYT48YnI+Jm5ic3A7Jm5ic3A7Jm5ic3A7PGEgdGFyZ2V0PSJfYmxhbmsiIHN0eWxlPSJjb2xvcjojZmZmOyIgaHJlZj0iL2tpYmFuYS8iPktpYmFuYTwvYT4mbmJzcDsmbmJzcDsmbmJzcDsmbmJzcDsmbmJzcDsmbmJzcDs8YSB0YXJnZXQ9Il9ibGFuayIgc3R5bGU9ImNvbG9yOiNmZmY7IiBocmVmPSIvY2VyZWJyby8jL292ZXJ2aWV3P2hvc3Q9aHR0cDolMkYlMkZsb2NhbGhvc3Q6OTIwMCI+Q2VyZWJybzwvYT4nOwogICAgc3ViX2ZpbHRlciAnU2lnbiBpbjwvYnV0dG9uPicgJ1NpZ24gaW48L2J1dHRvbj48YnI+PGJyPjxhIHRhcmdldD0iX2JsYW5rIiBzdHlsZT0iY29sb3I6I2ZmZjsiIGhyZWY9Ii9raWJhbmEvIj5LaWJhbmE8L2E+PGJyPjxhIHRhcmdldD0iX2JsYW5rIiBzdHlsZT0iY29sb3I6I2ZmZjsiIGhyZWY9Ii9jZXJlYnJvLyMvb3ZlcnZpZXc/aG9zdD1odHRwOiUyRiUyRmxvY2FsaG9zdDo5MjAwIj5DZXJlYnJvPC9hPic7CiAgICBzdWJfZmlsdGVyX29uY2Ugb2ZmOwogIH0KCiAgbG9jYXRpb24gfiBeL2tpYmFuYSguKikkIHsKICAgIHByb3h5X2h0dHBfdmVyc2lvbiAxLjE7CiAgICBwcm94eV9zZXRfaGVhZGVyIFVwZ3JhZGUgJGh0dHBfdXBncmFkZTsKICAgIHByb3h5X3NldF9oZWFkZXIgQ29ubmVjdGlvbiAndXBncmFkZSc7CiAgICBwcm94eV9zZXRfaGVhZGVyIEhvc3QgJGhvc3Q7CiAgICBwcm94eV9jYWNoZV9ieXBhc3MgJGh0dHBfdXBncmFkZTsKICAgIHByb3h5X3Bhc3MgIGh0dHA6Ly9sb2NhbGhvc3Q6NTYwMTsKICAgIHJld3JpdGUgXi9raWJhbmEvKC4qKSQgLyQxIGJyZWFrOwogICAgcmV3cml0ZSBeL2tpYmFuYSQgL2tpYmFuYS87CiAgICBhdXRoX2Jhc2ljICJSZXN0cmljdGVkIENvbnRlbnQiOwogICAgYXV0aF9iYXNpY191c2VyX2ZpbGUgL2V0Yy9uZ2lueC8ua2liYW5hX2F1dGg7CiAgfQoKICBsb2NhdGlvbiAvY2VyZWJyby8gewogICAgcHJveHlfcGFzcyBodHRwOi8vbG9jYWxob3N0OjkwMDAvOwogICAgcHJveHlfc2V0X2hlYWRlciBIb3N0ICRob3N0OwogICAgYXV0aF9iYXNpYyAiUmVzdHJpY3RlZCBDb250ZW50IjsKICAgIGF1dGhfYmFzaWNfdXNlcl9maWxlIC9ldGMvbmdpbngvLmNlcmVicm9fYXV0aDsKICB9Cn0K"

# Check for and remove old version of nginx setup files
old_configs=("/etc/nginx/sites-available/cerebro" "/etc/nginx/sites-available/kibana" "/etc/nginx/sites-available/timesketch")
for i in "${old_configs[@]}"
do
  sudo rm -f -- $i
done

# Configure default site
echo $nginx_conf |base64 -d |sudo tee /etc/nginx/sites-available/default

# Add domain name (if changed) and enable basic auth
if [[ ! -z "$new_domain" ]]; then
  echo "Replacing default server name '_' with '$new_domain'"
  sudo sed -i "s/_\;/$new_domain\;/g" /etc/nginx/sites-available/default
fi

# Configure Kibana Credentials
k_user="kibuser_$(openssl rand -base64 3)"
k_pass=$(openssl rand -base64 32)
echo $k_pass | sudo htpasswd -i -c /etc/nginx/.kibana_auth $k_user

# Configure Cerebro Credentials
c_user="ceruser_$(openssl rand -base64 3)"
c_pass=$(openssl rand -base64 32)
echo $c_pass | sudo htpasswd -i -c /etc/nginx/.cerebro_auth $c_user

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
if [[ ! -z "$new_domain" ]]; then
  echo "Domain: '$new_domain'"
else
  echo "Domain: <not set so listening to all requests>"
  new_domain="exampledomain.com"
fi
echo "The following are now being reverse proxied with authentication at: "
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
echo "WARNING!!! Encryption is not enabled and it is strongly recommended to enable it"
echo ""
echo ""
echo "Letsencrypt is installed and able to encrypt these sites if a valid, internet routable FQDN is used. It is not enabled by default"
echo "To start the Letsencrypt setup process type the following and follow the installation prompts:"
echo "sudo certbot --nginx"
