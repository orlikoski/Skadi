#!/bin/bash
echo "Installing / Updating / Configuring the following:"
echo "  -Change hostname to 'skadi'"
echo "  -CDQR"
echo "  -CyLR"
echo "  -Docker"
echo "  -Plaso"
echo "  -Mono"
echo "  -ELK"
echo "    -Elasticsearch"
echo "    -Logstash"
echo "    -Kibana"
echo "  -Redis"
echo "  -Neo4j"
echo "  -Celery"
echo "  -Timesketch"
echo "  -Cerebro"
echo "  -Other Dependancies"
echo "    -vim"
echo "    -openssh-server"
echo "    -curl"
echo "    -software-properties-common"
echo "    -unzip"
echo "    -htop"
echo "    -ca-certificates"
echo "    -apt-transport-https"
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

# Set Hostname to skadi
newhostname='skadi'
oldhostname=$(</etc/hostname)
sudo hostname $newhostname >/dev/null 2>&1
sudo sed -i "s/$oldhostname/$newhostname/g" /etc/hosts >/dev/null 2>&1
echo skadi |sudo tee /etc/hostname >/dev/null 2>&1
sudo systemctl restart systemd-logind.service >/dev/null 2>&1

# Install dependancies:
sudo sed -i 's/deb cdrom/#deb cdrom/g' /etc/apt/sources.list
sudo apt update -y
sudo apt dist-upgrade -y
sudo apt install -y vim openssh-server curl software-properties-common unzip htop ca-certificates apt-transport-https

sudo add-apt-repository ppa:gift/stable -y
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" -y
sudo apt update -y
sudo apt dist-upgrade -y

# Install Docker
sudo apt-get install docker-ce -y

# Install Plaso
sudo apt install -y python-software-properties python-plaso plaso-tools
sudo apt autoremove -y

# Install Mono
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF
echo "deb http://download.mono-project.com/repo/ubuntu stable-xenial main" | sudo tee /etc/apt/sources.list.d/mono-official-stable.list
sudo apt update -y
sudo apt dist-upgrade -y
sudo apt install mono-devel -y

#Install and Configure Elasticsearch
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
echo "deb https://artifacts.elastic.co/packages/5.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-5.x.list
sudo add-apt-repository ppa:webupd8team/java -y
sudo apt update -y
sudo apt dist-upgrade -y
echo debconf shared/accepted-oracle-license-v1-1 select true | sudo debconf-set-selections
echo debconf shared/accepted-oracle-license-v1-1 seen true | sudo debconf-set-selections
sudo apt install elasticsearch oracle-java8-installer -y

sudo sed -i 's/#network.host\: 192.168.0.1/network.host\: localhost/g' /etc/elasticsearch/elasticsearch.yml
# Assign jvm.options to 1/2 the allocated memory at run time
# Default Values
# -Xms1g
# -Xmx1g
total_mem=$(free -h |awk '/Mem/{print substr($2, 1, length($2)-1)}'|cut -d'.' -f1)
mem_size=$(($total_mem/2))
echo "Setting jvm.options memory size to $mem_size GB. This should be half (always rounding down) of total memory on machine"
sudo sed -i "s/-Xms1/-Xms$mem_size/g" /etc/elasticsearch/jvm.options
sudo sed -i "s/-Xmx1/-Xmx$mem_size/g" /etc/elasticsearch/jvm.options

sudo systemctl daemon-reload
sudo systemctl restart elasticsearch
sudo systemctl enable elasticsearch

# Install Redis
sudo add-apt-repository ppa:chris-lea/redis-server -y
sudo apt update -y
sudo apt dist-upgrade -y
sudo apt install redis-server -y
sudo systemctl daemon-reload
sudo systemctl restart redis-server
sudo systemctl enable redis-server

# Install and Configure Neo4j
neo4juser='neo4j'
neo4jpassword=$(openssl rand -base64 32)
wget -O - https://debian.neo4j.org/neotechnology.gpg.key | sudo apt-key add -
echo 'deb http://debian.neo4j.org/repo stable/' | sudo tee -a /etc/apt/sources.list.d/neo4j.list
sudo apt update -y
sudo apt dist-upgrade -y
sudo apt install neo4j -y
sudo /usr/bin/neo4j-admin set-initial-password $neo4jpassword
sudo chown -R neo4j:neo4j /var/lib/neo4j/
sudo systemctl daemon-reload
sudo systemctl restart neo4j
sudo systemctl enable neo4j


# Install and Configure Kibana and Logstash
sudo apt install kibana logstash -y
sudo sed -i 's@#server.host\: \"localhost\"@server.host\: \"0.0.0.0\"@g' /etc/kibana/kibana.yml
sudo systemctl daemon-reload
sudo systemctl restart kibana
sudo systemctl enable kibana

# Configure Celery
celery_service="W1VuaXRdCkRlc2NyaXB0aW9uPUNlbGVyeSBTZXJ2aWNlCkFmdGVyPW5ldHdvcmsudGFyZ2V0CgpbU2VydmljZV0KVHlwZT1mb3JraW5nClVzZXI9Y2VsZXJ5Ckdyb3VwPWNlbGVyeQpQSURGaWxlPS9vcHQvY2VsZXJ5L2NlbGVyeS5waWRsb2NrCgpFeGVjU3RhcnQ9L3Vzci9sb2NhbC9iaW4vY2VsZXJ5IG11bHRpIHN0YXJ0IHNpbmdsZS13b3JrZXIgLUEgdGltZXNrZXRjaC5saWIudGFza3Mgd29ya2VyIC0tbG9nbGV2ZWw9aW5mbyAtLWxvZ2ZpbGU9L3Zhci9sb2cvY2VsZXJ5X3dvcmtlciAtLXBpZGZpbGU9L29wdC9jZWxlcnkvY2VsZXJ5LnBpZGxvY2sKRXhlY1N0b3A9L3Vzci9sb2NhbC9iaW4vY2VsZXJ5IG11bHRpIHN0b3B3YWl0IHNpbmdsZS13b3JrZXIgLS1waWRmaWxlPS9vcHQvY2VsZXJ5L2NlbGVyeS5waWRsb2NrIC0tbG9nZmlsZT0vdmFyL2xvZy9jZWxlcnlfd29ya2VyCkV4ZWNSZWxvYWQ9L3Vzci9sb2NhbC9iaW4vY2VsZXJ5IG11bHRpIHJlc3RhcnQgc2luZ2xlLXdvcmtlciAtLXBpZGZpbGU9L29wdC9jZWxlcnkvY2VsZXJ5LnBpZGxvY2sgLS1sb2dmaWxlPS92YXIvbG9nL2NlbGVyeV93b3JrZXIKCgpbSW5zdGFsbF0KV2FudGVkQnk9bXVsdGktdXNlci50YXJnZXQK"
sudo useradd -r -s /bin/false celery
sudo mkdir -p /opt/celery
sudo touch /var/log/celery_worker
sudo touch /opt/celery/celery.pidlock
sudo chown -R celery:celery /opt/celery
sudo chown -R celery:celery /opt/celery/celery.pidlock

sudo chown -R celery:celery /var/log/celery_worker
echo $celery_service |base64 -d | sudo tee /etc/systemd/system/celery.service
sudo chmod g+w /etc/systemd/system/celery.service
sudo systemctl daemon-reload
sudo systemctl restart celery
sudo systemctl enable celery

# Install and Configure TimeSketch
SECRET_KEY="$(openssl rand -base64 32 | sha256sum)"
psql_pw=$(openssl rand -base64 32 | sha256sum)

sudo mkdir -p /etc/elasticsearch/scripts
sudo wget -O /etc/elasticsearch/scripts/add_label.groovy https://raw.githubusercontent.com/google/timesketch/master/contrib/add_label.groovy
sudo wget -O /etc/elasticsearch/scripts/toggle_label.groovy https://raw.githubusercontent.com/google/timesketch/master/contrib/toggle_label.groovy
sudo apt install postgresql -y
sudo apt install python-psycopg2 -y

echo "local all timesketch md5"|sudo tee -a /etc/postgresql/9.5/main/pg_hba.conf
sudo systemctl restart postgresql.service
echo "create user timesketch with password '$psql_pw';" | sudo -u postgres psql || true
echo "create database timesketch owner timesketch;" | sudo -u postgres psql || true

sudo apt install python-pip python-dev libffi-dev -y
sudo -H pip install --upgrade pip
sudo -H pip install timesketch

sudo cp /usr/local/share/timesketch/timesketch.conf /etc/
sudo sed -i "s@SECRET_KEY = u''@SECRET_KEY = u'$SECRET_KEY'@g" /etc/timesketch.conf
sudo sed -i "s@<USERNAME>\:<PASSWORD>@timesketch\:$psql_pw@g" /etc/timesketch.conf
sudo sed -i "s@NEO4J_USERNAME = u''@NEO4J_USERNAME = u'$neo4juser'@g" /etc/timesketch.conf
sudo sed -i "s@NEO4J_PASSWORD = u''@NEO4J_PASSWORD = u'$neo4jpassword'@g" /etc/timesketch.conf
# Disabling for now but leaving for future use
#sudo sed -i "s/UPLOAD_ENABLED = False/UPLOAD_ENABLED = True/g" /etc/timesketch.conf
#sudo sed -i "s/GRAPH_BACKEND_ENABLED = False/GRAPH_BACKEND_ENABLED = True/g" /etc/timesketch.conf


timesketchpassword="skadi"
timesketchuser="skadi"
tsctl add_user -u "$timesketchuser" -p "$timesketchpassword"

timesketch_service="W1VuaXRdCkRlc2NyaXB0aW9uPVRpbWVTa2V0Y2ggU2VydmljZQpBZnRlcj1uZXR3b3JrLnRhcmdldAoKW1NlcnZpY2VdClVzZXI9dGltZXNrZXRjaApHcm91cD10aW1lc2tldGNoCkV4ZWNTdGFydD0vdXNyL2xvY2FsL2Jpbi90c2N0bCBydW5zZXJ2ZXIgLWggMC4wLjAuMCAtcCA1MDAwIC0tdGhyZWFkZWQgLS1wYXNzdGhyb3VnaC1lcnJvcnMgCgpbSW5zdGFsbF0KV2FudGVkQnk9bXVsdGktdXNlci50YXJnZXQK"

sudo useradd -r -s /bin/false timesketch

echo $timesketch_service |base64 -d | sudo tee /etc/systemd/system/timesketch.service
sudo chmod g+w /etc/systemd/system/timesketch.service
sudo systemctl daemon-reload
sudo systemctl restart timesketch.service
sudo systemctl enable timesketch.service

# Install and Configure Cerebro
cerebro_service="W1VuaXRdCkRlc2NyaXB0aW9uPUNlcmVicm8gU2VydmljZQpBZnRlcj1uZXR3b3JrLnRhcmdldAoKW1NlcnZpY2VdClVzZXI9Y2VyZWJybwpHcm91cD1jZXJlYnJvCkV4ZWNTdGFydD0vb3B0L2NlcmVicm8vY2VyZWJyby0wLjcuMi9iaW4vY2VyZWJybwoKW0luc3RhbGxdCldhbnRlZEJ5PW11bHRpLXVzZXIudGFyZ2V0Cg=="
cerebro_secret=$(openssl rand -base64 32 | sha256sum)
sudo useradd -r -s /bin/false cerebro
sudo mkdir /opt/cerebro

cerebro_version="0.7.2"
sudo wget -O "/opt/cerebro/cerebro-$cerebro_version.tgz" "https://github.com/lmenezes/cerebro/releases/download/v$cerebro_version/cerebro-$cerebro_version.tgz"
sudo tar xzf "/opt/cerebro/cerebro-$cerebro_version.tgz" -C "/opt/cerebro/"
sudo rm -rf "/opt/cerebro/cerebro-$cerebro_version.tgz"
sudo chown -R cerebro:cerebro /opt/cerebro
sudo chmod +w /opt/cerebro
sudo sed -i "s@./cerebro.db@/opt/cerebro/cerebro-$cerebro_version/cerebro.db@g" "/opt/cerebro/cerebro-$cerebro_version/conf/application.conf"
sudo sed -i "s/secret = .*/secret = \"$cerebro_secret\"/g"  "/opt/cerebro/cerebro-$cerebro_version/conf/application.conf"
sudo sed -i "s@hosts = \[@hosts = \[\\n\  {\\n    host = \"http\://localhost\:9200\"\\n    name = \"SKADI\"\\n  \}@g" "/opt/cerebro/cerebro-$cerebro_version/conf/application.conf"
#sudo sed -i "s@basePath = \"/\"@basePath = \"/opt/cerebro/cerebro-$cerebro_version\"@g" "/opt/cerebro/cerebro-$cerebro_version/conf/application.conf"

cerebro_config="aG9zdHMgPSBbCiAgewogICAgaG9zdCA9ICJodHRwOi8vbG9jYWxob3N0OjkyMDAiCiAgICBuYW1lID0gIkNDRi1WTSIKICB9Cg=="
echo $cerebro_service |base64 -d | sudo tee /etc/systemd/system/cerebro.service
sudo chmod g+w /etc/systemd/system/cerebro.service
sudo systemctl daemon-reload
sudo systemctl restart cerebro.service
sudo systemctl enable cerebro.service

# Installs and Configures CDQR and CyLR
echo "Updating CDQR"
wget -O /tmp/cdqr.py https://raw.githubusercontent.com/orlikoski/CDQR/master/src/cdqr.py
chmod a+x /tmp/cdqr.py
sudo mv /tmp/cdqr.py /usr/local/bin/cdqr.py
echo "CDQR is in /usr/local/bin/cdqr.py"


echo "Updating CyLR"
#Building the CyLR link
LATEST_RELEASE=$(curl -L -s -H 'Accept: application/json' https://github.com/orlikoski/CyLR/releases/latest)
LATEST_VERSION=$(echo $LATEST_RELEASE | sed -e 's/.*"tag_name":"\([^"]*\)".*/\1/')
ARTIFACT_URL="https://github.com/orlikoski/CyLR/releases/download/$LATEST_VERSION/CyLR.zip"


wget -O /tmp/CyLR.zip $ARTIFACT_URL
if [ ! -d "/opt/CyLR" ]; then
  sudo mkdir /opt/CyLR/
  sudo chmod 777 /opt/CyLR
else
  sudo rm -rf /opt/CyLR/*
fi
if [ -d "CyLR/" ]; then
  sudo rm -rf CyLR/
fi

unzip /tmp/CyLR.zip -d /opt/CyLR/
if [ $? -eq 0 ]; then
  echo "CyLR installed into /opt/CyLR/"
else
  echo "Error, install unzip and try again"
  sudo apt install unzip -y
  unzip /tmp/CyLR.zip -d /opt/CyLR/
  if [ $? -ne 0 ]; then
    echo "CyLR Update failed"
  else
    echo "CyLR is in /opt/CyLR/"
  fi
fi
rm /tmp/CyLR.zip
echo ""
echo ""

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


# Configure default site
echo $nginx_conf |base64 -d |sudo tee /etc/nginx/sites-available/default

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

new_domain="Hostname or IP Address"
echo ""
echo ""
echo ""
echo ""
echo ""
echo "Nginx reverse proxy setup is complete with the following:"
echo "Hostname: '$new_domain'"
echo "The following are now being reverse proxied with authentication at: "
echo ""
echo "  TimeSketch:"
echo "   - 'http://$new_domain'"
echo "     - Username: $timesketchuser"
echo "     - Password: $timesketchpassword"
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

echo ""
echo "Logstash and automation_grpc are installed but not enabled by default"
echo "To enable run the following commands"
echo "    sudo systemctl restart logstash automation_grpc_service"
echo "    sudo systemctl enable logstash automation_grpc_service"
echo ""
echo ""
clear
echo "Installed Software Version Checks (Where it is supported)"
/usr/bin/log2timeline.py --version
/usr/local/bin/cdqr.py --version
mono /opt/CyLR/CyLR.exe --version |grep Version
docker --version
echo "ELK Version: $(curl --silent -XGET 'localhost:9200' |awk '/number/{print substr($3, 1, length($3)-1)}')"
redis-server --version
neo4j --version
echo "Celery version: $(celery --version)"
echo "Cerebro version: $cerebro_version"
echo ""
echo ""

echo "System Health Checks"
# system health checks
declare -a services=('elasticsearch' 'postgresql' 'celery' 'neo4j' 'redis' 'kibana' 'timesketch')
# Ensure all Services are started
for item in "${services[@]}"
do
    echo "  Bringing up $item"
    sudo systemctl restart $item
    sleep 1
done

echo ""

for item in "${services[@]}"
do
    echo "  $item service is: $(systemctl is-active $item)"
done
exec bash
