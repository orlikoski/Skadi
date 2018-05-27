#!/bin/bash
echo "Upgrading Skadi 2018.1 to 2018.2"
echo "*********** WARNING ***********"
echo "All data in the ELK will be lost and the data in TimeSketch could be corrupted (due to the loss of Elasticsearch data) due to this upgrade"
echo "Additionally, the `Post Installation` instructions from https://github.com/orlikoski/Skadi/wiki/Installation:-OpenSSL-Signed-Installation-Guide will need to be followed"
echo "If this seems like too much work are will create issues, it may be easier to use the newest version of Skadi and skip the upgrade process"
echo ""
echo "root or sudo privileges are required for this installation"
echo "*********** WARNING ***********"
echo ""
read -n 1 -r -s -p "Press any key to continue... or CTRL+C to exit (nothing has been installed)"
echo ""
echo ""
set -e
# This script converts Skadi 2018.1 to 2018.2
# NOTE: All of the data in the ELK stack will be lost
sudo cp /etc/elasticsearch/scripts/add_label.groovy /tmp/
sudo cp /etc/elasticsearch/scripts/toggle_label.groovy /tmp/

sudo apt purge elasticsearch kibana logstash -y
sudo rm -rf /var/lib/elasticsearch /etc/elasticsearch /var/lib/kibana
sudo -H pip install --upgrade pip
sudo -H pip2 install --upgrade pip
sudo -H pip2 uninstall elasticsearch -y

sudo rm  /etc/apt/sources.list.d/elastic-*
echo "deb https://artifacts.elastic.co/packages/5.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-5.x.list
sudo apt update && sudo apt dist-upgrade -y
sudo apt autoremove -y

sudo apt install elasticsearch kibana logstash -y
sudo cp /tmp/add_label.groovy /etc/elasticsearch/scripts/
sudo cp /tmp/toggle_label.groovy /etc/elasticsearch/scripts/

sudo -H pip install --upgrade botocore boto3 gunicorn

sudo systemctl stop elasticsearch logstash kibana cerebro timesketch
sudo sed -i 's@#server.host\: \"localhost\"@server.host\: \"0.0.0.0\"@g' /etc/kibana/kibana.yml
sudo sed -i 's/#network.host\: 192.168.0.1/network.host\: localhost/g' /etc/elasticsearch/elasticsearch.yml

# Assign jvm.options to 2GB
# Default Values
# -Xms1g
# -Xmx1g
sudo sed -i "s/-Xms1/-Xms2/g" /etc/elasticsearch/jvm.options
sudo sed -i "s/-Xmx1/-Xmx2/g" /etc/elasticsearch/jvm.options

timesketch_service="W1VuaXRdCkRlc2NyaXB0aW9uPVRpbWVTa2V0Y2ggU2VydmljZQpBZnRlcj1uZXR3b3JrLnRhcmdldAoKW1NlcnZpY2VdClVzZXI9dGltZXNrZXRjaApHcm91cD10aW1lc2tldGNoCkV4ZWNTdGFydD0vdXNyL2xvY2FsL2Jpbi9ndW5pY29ybiAtLXdvcmtlcnMgNCAtLWJpbmQgMTI3LjAuMC4xOjUwMDAgdGltZXNrZXRjaC53c2dpIAoKW0luc3RhbGxdCldhbnRlZEJ5PW11bHRpLXVzZXIudGFyZ2V0Cg=="
echo $timesketch_service |base64 -d | sudo tee /etc/systemd/system/timesketch.service
sudo systemctl daemon-reload
sudo systemctl restart timesketch

sudo systemctl restart elasticsearch logstash kibana cerebro timesketch
sudo /bin/systemctl daemon-reload &&
sudo /bin/systemctl enable elasticsearch logstash kibana &&
sudo /bin/systemctl start elasticsearch logstash kibana

# Install Networking pack
echo "Now installing secure networking pack"
# Disable IPv6
echo "net.ipv6.conf.all.disable_ipv6 = 1" | sudo tee -a /etc/sysctl.d/99-sysctl.conf
echo "net.ipv6.conf.default.disable_ipv6 = 1" | sudo tee -a /etc/sysctl.d/99-sysctl.conf
echo "net.ipv6.conf.lo.disable_ipv6 = 1" | sudo tee -a /etc/sysctl.d/99-sysctl.conf
sudo sysctl -p

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

# Configure Kibana Credentials
k_user="skadi"
k_pass="skadi"
echo $k_pass | sudo htpasswd -i -c /etc/nginx/.kibana_auth $k_user

# Configure Cerebro Credentials
c_user="skadi"
c_pass="skadi"
echo $c_pass | sudo htpasswd -i -c /etc/nginx/.cerebro_auth $c_user

sudo systemctl restart nginx
sudo systemctl enable nginx

# Install and Configure Letsencrypt
sudo apt update -y
sudo apt install software-properties-common -y
sudo add-apt-repository ppa:certbot/certbot -y
sudo apt update -y
sudo apt install python-certbot-nginx -y

# Set default number of replicas to 0 (this prevents unassigned shards in default Skadi)
curl -X PUT "localhost:9200/_template/all" -H 'Content-Type: application/json' -d'
{
  "template": "*",
  "settings": {
    "number_of_replicas": 0
  }
}
'

# Configure Kibana Credentials
k_user="skadi"
k_pass="skadi"
echo $k_pass | sudo htpasswd -i -c /etc/nginx/.kibana_auth $k_user

# Configure Cerebro Credentials
c_user="skadi"
c_pass="skadi"
echo $c_pass | sudo htpasswd -i -c /etc/nginx/.cerebro_auth $c_user

sudo systemctl restart nginx
sudo systemctl enable nginx

echo ""
echo ""
echo ""
echo ""
echo "The Nginx reverse proxy setup is complete with the following:"
new_domain="`hostname or IP address`"
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
echo "WARNING!!! Encryption is not enabled and it is strongly recommended to enable it before using on any type of production network"
echo ""
echo ""
echo ""
echo ""
echo "The upgrade from 2018.1 to 2018.2 has been mostly completed"
echo "All data in the ELK has been lost and the data in TimeSketch could be corrupted (due to the loss of Elasticsearch data) due to this upgrade"
echo "Additionally, the `Post Installation` instructions from https://github.com/orlikoski/Skadi/wiki/Installation:-OpenSSL-Signed-Installation-Guide need to be followed"
