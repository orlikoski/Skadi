#!/bin/bash
set -e

default_skadi_passwords=${DEFAULT_PASSWORDS:-"false"}

if [ $default_skadi_passwords = "false" ]
  then
    echo "Using random username and passwords for TimeSketch and Nginx proxy"
else
    echo "Using Skadi default username and password of skadi:skadi for TimeSketch and Nginx proxy"
fi

# Set Hostname to skadi
newhostname='skadi'
oldhostname=$(</etc/hostname)
sudo hostname $newhostname >/dev/null 2>&1
sudo sed -i "s/$oldhostname/$newhostname/g" /etc/hosts >/dev/null 2>&1
echo skadi |sudo tee /etc/hostname >/dev/null 2>&1
sudo systemctl restart systemd-logind.service >/dev/null 2>&1

# Create Skadi user
SKADI_USER="skadi"
SKADI_PASS="skadi"
SKADI_USER_HOME="/home/skadi"

if ! id -u $SKADI_USER >/dev/null 2>&1; then
    echo "==> Creating $SKADI_USER user"
    /usr/sbin/groupadd $SKADI_USER
    /usr/sbin/useradd $SKADI_USER -g $SKADI_USER -G sudo -d $SKADI_USER_HOME --create-home -s "/bin/bash"
    echo "${SKADI_USER}:${SKADI_PASS}" | chpasswd
fi

# Set up sudo
echo "==> Giving ${SKADI_USER} sudo powers"
echo "${SKADI_USER}        ALL=(ALL)       NOPASSWD: ALL" > /etc/sudoers.d/$SKADI_USER
chmod 440 /etc/sudoers.d/$SKADI_USER

sudo apt-get install curl wget software-properties-common -y

# Set Timezone to UTC
sudo timedatectl set-timezone UTC

# Add Repositories required:
sudo sed -i 's/deb cdrom/#deb cdrom/g' /etc/apt/sources.list
sudo add-apt-repository ppa:gift/stable -y
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" -y

# Add Repositories for Mono
# sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF
# echo "deb http://download.mono-project.com/repo/ubuntu stable-xenial main" | sudo tee /etc/apt/sources.list.d/mono-official-stable.list

# Add Repositories for Elasticsearch
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
echo "deb https://artifacts.elastic.co/packages/6.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-6.x.list
sudo add-apt-repository ppa:webupd8team/java -y

# Install Redis
sudo add-apt-repository ppa:chris-lea/redis-server -y

# Add Repositories for Neo4j
wget -O - https://debian.neo4j.org/neotechnology.gpg.key | sudo apt-key add -
echo 'deb http://debian.neo4j.org/repo stable/' | sudo tee -a /etc/apt/sources.list.d/neo4j.list

# Add Repositories for Letsencrypt
sudo add-apt-repository ppa:certbot/certbot -y

# Update apt and apply all updates
sudo apt-get update -y
sudo apt-get dist-upgrade -y
sudo apt-get autoremove -y

# Install Most Of The Things
# sudo apt-get install -y vim screen openssh-server unzip htop ca-certificates apt-transport-https docker-ce python-software-properties python-plaso plaso-tools mono-devel redis-server neo4j postgresql python-psycopg2 python-pip python-dev libffi-dev nginx apache2-utils python-certbot-nginx
sudo apt-get install -y vim screen openssh-server unzip htop ca-certificates apt-transport-https docker-ce python-software-properties redis-server neo4j postgresql python-psycopg2 python-pip python-dev libffi-dev nginx apache2-utils python-certbot-nginx npm

# Install Java and ELK
echo debconf shared/accepted-oracle-license-v1-1 select true | sudo debconf-set-selections
echo debconf shared/accepted-oracle-license-v1-1 seen true | sudo debconf-set-selections
sudo apt-get install -y oracle-java8-installer
sudo apt-get install -y elasticsearch kibana logstash
# Update pip
sudo -H pip install --upgrade pip

# Install Gunicorn, TimeSketch, and Plaso
# sudo -H pip install timesketch
sudo -H pip install gunicorn
git clone https://github.com/google/timesketch.git
cd timesketch/
sudo -H pip install . --upgrade
sudo apt-get install -y python-plaso plaso-tools




sudo sed -i 's/#network.host\: 192.168.0.1/network.host\: localhost/g' /etc/elasticsearch/elasticsearch.yml
# Assign jvm.options to 1/2 the allocated memory at run time
# Default Values
# -Xms1g
# -Xmx1g
#total_mem=$(free -h |awk '/Mem/{print substr($2, 1, length($2)-1)}'|cut -d'.' -f1)
mem_size="2"
echo "Setting jvm.options memory size to $mem_size GB"
sudo sed -i "s/-Xms1/-Xms$mem_size/g" /etc/elasticsearch/jvm.options
sudo sed -i "s/-Xmx1/-Xmx$mem_size/g" /etc/elasticsearch/jvm.options

sudo systemctl restart elasticsearch
sudo systemctl enable elasticsearch

# Create a template in ES that sets the number of replicas for all indexes to 0
echo "Waiting 60 seconds for Elasticsearch to initialize"
sleep 60 # Give ES time to start
echo "Setting the default number of replicas to 0"
curl -XPUT 'localhost:9200/_template/number_of_replicas' -d '{"template": "*","settings": {"number_of_replicas": 0}}' -H'Content-Type: application/json'

# Configure/Enable Redis
sudo systemctl restart redis-server
sudo systemctl enable redis-server

# Configure Neo4j
neo4juser='neo4j'
neo4jpassword=$(openssl rand -base64 32)
sudo /usr/bin/neo4j-admin set-initial-password $neo4jpassword
sudo chown -R neo4j:neo4j /var/lib/neo4j/
sudo systemctl restart neo4j
sudo systemctl enable neo4j


# Configure Kibana
sudo sed -i 's@#server.host\: \"localhost\"@server.host\: \"localhost\"@g' /etc/kibana/kibana.yml
sudo systemctl restart kibana
sudo systemctl enable kibana

# Configure TimeSketch
SECRET_KEY="$(openssl rand -base64 32 | sha256sum)"
psql_pw=$(openssl rand -base64 32 | sha256sum)

echo "local all timesketch md5"|sudo tee -a /etc/postgresql/9.5/main/pg_hba.conf
sudo systemctl restart postgresql.service
echo "create user timesketch with password '$psql_pw';" | sudo -u postgres psql || true
echo "create database timesketch owner timesketch;" | sudo -u postgres psql || true

sudo cp /usr/local/share/timesketch/timesketch.conf /etc/
sudo sed -i "s@SECRET_KEY = u'<KEY_GOES_HERE>'@SECRET_KEY = u'$SECRET_KEY'@g" /etc/timesketch.conf
sudo sed -i "s@<USERNAME>\:<PASSWORD>@timesketch\:$psql_pw@g" /etc/timesketch.conf
sudo sed -i "s@NEO4J_USERNAME = u'neo4j'@NEO4J_USERNAME = u'$neo4juser'@g" /etc/timesketch.conf
sudo sed -i "s@NEO4J_PASSWORD = u'<N4J_PASSWORD>'@NEO4J_PASSWORD = u'$neo4jpassword'@g" /etc/timesketch.conf
sudo sed -i "s/UPLOAD_ENABLED = False/UPLOAD_ENABLED = True/g" /etc/timesketch.conf
sudo sed -i "s/GRAPH_BACKEND_ENABLED = False/GRAPH_BACKEND_ENABLED = True/g" /etc/timesketch.conf

if [ $default_skadi_passwords = "false" ]; then
  timesketchpassword=$(openssl rand -base64 32)
  timesketchuser="skadi_$(openssl rand -base64 3)"
else
  timesketchpassword="skadi"
  timesketchuser="skadi"
fi
tsctl add_user -u "$timesketchuser" -p "$timesketchpassword"
sudo useradd -r -s /bin/false timesketch

timesketch_service="W1VuaXRdCkRlc2NyaXB0aW9uPVRpbWVTa2V0Y2ggU2VydmljZQpBZnRlcj1uZXR3b3JrLnRhcmdldAoKW1NlcnZpY2VdClVzZXI9dGltZXNrZXRjaApHcm91cD10aW1lc2tldGNoCkV4ZWNTdGFydD0vdXNyL2xvY2FsL2Jpbi9ndW5pY29ybiAtLXdvcmtlcnMgNCAtLWJpbmQgMTI3LjAuMC4xOjUwMDAgdGltZXNrZXRjaC53c2dpCgpbSW5zdGFsbF0KV2FudGVkQnk9bXVsdGktdXNlci50YXJnZXQK"
echo $timesketch_service |base64 -d | sudo tee /etc/systemd/system/timesketch.service
sudo chmod g+w /etc/systemd/system/timesketch.service
sudo systemctl daemon-reload
sudo systemctl restart timesketch.service
sudo systemctl enable timesketch.service

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

# Configure Cerebro
cerebro_secret=$(openssl rand -base64 32 | sha256sum)
sudo useradd -r -s /bin/false cerebro
sudo mkdir /opt/cerebro

cerebro_version="0.8.1"
sudo wget -O "/opt/cerebro/cerebro-$cerebro_version.tgz" "https://github.com/lmenezes/cerebro/releases/download/v$cerebro_version/cerebro-$cerebro_version.tgz"
sudo tar xzf "/opt/cerebro/cerebro-$cerebro_version.tgz" -C "/opt/cerebro/"
sudo rm -rf "/opt/cerebro/cerebro-$cerebro_version.tgz"
sudo chown -R cerebro:cerebro /opt/cerebro
sudo chmod +w /opt/cerebro
sudo sed -i "s@./cerebro.db@/opt/cerebro/cerebro-$cerebro_version/cerebro.db@g" "/opt/cerebro/cerebro-$cerebro_version/conf/application.conf"
sudo sed -i "s/secret = .*/secret = \"$cerebro_secret\"/g"  "/opt/cerebro/cerebro-$cerebro_version/conf/application.conf"
sudo sed -i "s@hosts = \[@hosts = \[\\n\  {\\n    host = \"http\://localhost\:9200\"\\n    name = \"SKADI\"\\n  \}@g" "/opt/cerebro/cerebro-$cerebro_version/conf/application.conf"

cerebro_service="W1VuaXRdCkRlc2NyaXB0aW9uPUNlcmVicm8gU2VydmljZQpBZnRlcj1uZXR3b3JrLnRhcmdldAoKW1NlcnZpY2VdClVzZXI9Y2VyZWJybwpHcm91cD1jZXJlYnJvCkV4ZWNTdGFydD0vb3B0L2NlcmVicm8vY2VyZWJyby12ZXJzaW9uL2Jpbi9jZXJlYnJvIC1EaHR0cC5hZGRyZXNzPTEyNy4wLjAuMQoKW0luc3RhbGxdCldhbnRlZEJ5PW11bHRpLXVzZXIudGFyZ2V0Cg=="
echo $cerebro_service |base64 -d | sudo tee /etc/systemd/system/cerebro.service
sudo sed -i "s/cerebro-version/cerebro-$cerebro_version/g" /etc/systemd/system/cerebro.service
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
# Building the CyLR link
cylr_files=( "CyLR_linux-x64.zip" "CyLR_osx-x64.zip" "CyLR_win-x64.zip" "CyLR_win-x86.zip")
LATEST_RELEASE=$(curl -L -s -H 'Accept: application/json' https://github.com/orlikoski/CyLR/releases/latest)
LATEST_VERSION=$(echo $LATEST_RELEASE | sed -e 's/.*"tag_name":"\([^"]*\)".*/\1/')
ARTIFACT_URL="https://github.com/orlikoski/CyLR/releases/download/$LATEST_VERSION/"

# Remove old versions
if [ -f /opt/CyLR/CyLR.exe ]; then
    sudo rm /opt/CyLR/CyLR.exe
fi
if [ -f /home/skadi/Desktop/CyLR.exe ]; then
    sudo rm /home/skadi/Desktop/CyLR.exe
fi

for cylrzip in "${cylr_files[@]}"
do
  if [ ! -d "/opt/CyLR" ]; then
    sudo mkdir /opt/CyLR/
    sudo chmod 777 /opt/CyLR
  else
    sudo rm -rf /opt/CyLR/$cylrzip
  fi
  wget -O "/opt/CyLR/$cylrzip" "$ARTIFACT_URL/$cylrzip" > /dev/null 2>&1
  if [ $? -ne 0 ]; then
    echo "CyLR Download of $cylrzip failed"
  else
      if [ -d "CyLR/" ]; then
        sudo rm -rf CyLR/
      fi
      echo "$cylrzip downloaded into /opt/CyLR/"
  fi
done
# If Skadi Desktop exists place link to CyLR folder on it
if [ -d /home/skadi/Desktop ]; then
    sudo ln -s /opt/CyLR /home/skadi/Desktop/CyLR
    sudo chown -h skadi:skadi /home/skadi/Desktop/CyLR
fi

unzip -o /opt/CyLR/CyLR_linux-x64.zip -d /tmp/ > /dev/null 2>&1
cylr_version=$(/tmp/CyLR --version |grep Version)
rm /tmp/CyLR > /dev/null 2>&1
echo "All CyLR Files Downloaded"
echo "Updated to $cylr_version"

echo ""
echo ""
sudo mkdir -p /opt/skadi
sudo wget -O /opt/skadi/update.sh https://raw.githubusercontent.com/orlikoski/Skadi/master/scripts/update.sh
sudo chown -R skadi:skadi /opt/skadi
sudo chmod +x /opt/skadi/update.sh
echo ""
echo ""
# Disable IPv6
echo "net.ipv6.conf.all.disable_ipv6 = 1" | sudo tee -a /etc/sysctl.d/99-sysctl.conf
echo "net.ipv6.conf.default.disable_ipv6 = 1" | sudo tee -a /etc/sysctl.d/99-sysctl.conf
echo "net.ipv6.conf.lo.disable_ipv6 = 1" | sudo tee -a /etc/sysctl.d/99-sysctl.conf
sudo sysctl -p

# Update Kibana to work with forwarding
sudo systemctl stop kibana
sudo sed -i "s@\#server.basePath: \"\"@server.basePath: \"/kibana\"@g" /etc/kibana/kibana.yml
sudo systemctl start kibana

# Configure Nginx and web utils
sudo ufw allow 'Nginx Full'
sudo ufw allow 'OpenSSH'
sudo ufw --force enable

# Configure Nginx for Kibana, Cerebro, and TimeSketch
nginx_conf="c2VydmVyIHsKICBsaXN0ZW4gODA7CiAgc2VydmVyX25hbWUgXzsKICBjbGllbnRfbWF4X2JvZHlfc2l6ZSAxMjI4OE07CiAgcHJveHlfY29ubmVjdF90aW1lb3V0IDkwMDBzOwogIHByb3h5X3JlYWRfdGltZW91dCA5MDAwczsKICByb290ICAgICAgICAgL3Vzci9zaGFyZS9uZ2lueC9odG1sOwogIGVycm9yX3BhZ2UgNDA0IC80MDQuaHRtbDsKICAgIGxvY2F0aW9uID0gLzQwNC5odG1sIHt9CiAgZXJyb3JfcGFnZSA1MDAgNTAyIDUwMyA1MDQgLzUweC5odG1sOwogICAgbG9jYXRpb24gPSAvNTB4Lmh0bWwge30KCiAgZXJyb3JfbG9nICAgL3Zhci9sb2cvbmdpbngvZXJyb3IubG9nOwogIGFjY2Vzc19sb2cgIC92YXIvbG9nL25naW54L2FjY2Vzcy5sb2c7CgogIGxvY2F0aW9uIC8gewogICAgcHJveHlfcGFzcyBodHRwOi8vbG9jYWxob3N0OjUwMDA7CiAgICBwcm94eV9odHRwX3ZlcnNpb24gMS4xOwogICAgcHJveHlfc2V0X2hlYWRlciBVcGdyYWRlICRodHRwX3VwZ3JhZGU7CiAgICBwcm94eV9zZXRfaGVhZGVyIENvbm5lY3Rpb24gJ3VwZ3JhZGUnOwogICAgcHJveHlfc2V0X2hlYWRlciBIb3N0ICRob3N0OwogICAgcHJveHlfY2FjaGVfYnlwYXNzICRodHRwX3VwZ3JhZGU7CiAgICBzdWJfZmlsdGVyICdMb2dvdXQ8L2E+JyAnTG9nb3V0PC9hPjxicj4mbmJzcDsmbmJzcDsmbmJzcDs8YSB0YXJnZXQ9Il9ibGFuayIgc3R5bGU9ImNvbG9yOiNmZmY7IiBocmVmPSIva2liYW5hLyI+S2liYW5hPC9hPiZuYnNwOyZuYnNwOyZuYnNwOyZuYnNwOyZuYnNwOyZuYnNwOzxhIHRhcmdldD0iX2JsYW5rIiBzdHlsZT0iY29sb3I6I2ZmZjsiIGhyZWY9Ii9jZXJlYnJvLyMvb3ZlcnZpZXc/aG9zdD1odHRwOiUyRiUyRmxvY2FsaG9zdDo5MjAwIj5DZXJlYnJvPC9hPiZuYnNwOyZuYnNwOyZuYnNwOyZuYnNwOyZuYnNwOyZuYnNwOzxhIHRhcmdldD0iX2JsYW5rIiBzdHlsZT0iY29sb3I6I2ZmZjsiIGhyZWY9Ii9jeWJlcmNoZWYvIj5DeWJlckNoZWY8L2E+JzsKICAgIHN1Yl9maWx0ZXIgJ1NpZ24gaW48L2J1dHRvbj4nICdTaWduIGluPC9idXR0b24+PGJyPjxicj48YSB0YXJnZXQ9Il9ibGFuayIgc3R5bGU9ImNvbG9yOiNmZmY7IiBocmVmPSIva2liYW5hLyI+S2liYW5hPC9hPjxicj48YSB0YXJnZXQ9Il9ibGFuayIgc3R5bGU9ImNvbG9yOiNmZmY7IiBocmVmPSIvY2VyZWJyby8jL292ZXJ2aWV3P2hvc3Q9aHR0cDolMkYlMkZsb2NhbGhvc3Q6OTIwMCI+Q2VyZWJybzwvYT48YnI+PGEgdGFyZ2V0PSJfYmxhbmsiIHN0eWxlPSJjb2xvcjojZmZmOyIgaHJlZj0iL2N5YmVyY2hlZi8iPkN5YmVyQ2hlZjwvYT4nOwogICAgc3ViX2ZpbHRlcl9vbmNlIG9mZjsKICB9CgogIGxvY2F0aW9uIH4gXi9raWJhbmEoLiopJCB7CiAgICBwcm94eV9odHRwX3ZlcnNpb24gMS4xOwogICAgcHJveHlfc2V0X2hlYWRlciBVcGdyYWRlICRodHRwX3VwZ3JhZGU7CiAgICBwcm94eV9zZXRfaGVhZGVyIENvbm5lY3Rpb24gJ3VwZ3JhZGUnOwogICAgcHJveHlfc2V0X2hlYWRlciBIb3N0ICRob3N0OwogICAgcHJveHlfY2FjaGVfYnlwYXNzICRodHRwX3VwZ3JhZGU7CiAgICBwcm94eV9wYXNzICBodHRwOi8vbG9jYWxob3N0OjU2MDE7CiAgICByZXdyaXRlIF4va2liYW5hLyguKikkIC8kMSBicmVhazsKICAgIHJld3JpdGUgXi9raWJhbmEkIC9raWJhbmEvOwogICAgYXV0aF9iYXNpYyAiUmVzdHJpY3RlZCBDb250ZW50IjsKICAgIGF1dGhfYmFzaWNfdXNlcl9maWxlIC9ldGMvbmdpbngvLnNrYWRpX2F1dGg7CiAgfQoKICBsb2NhdGlvbiAvY2VyZWJyby8gewogICAgcHJveHlfcGFzcyBodHRwOi8vbG9jYWxob3N0OjkwMDAvOwogICAgcHJveHlfc2V0X2hlYWRlciBIb3N0ICRob3N0OwogICAgYXV0aF9iYXNpYyAiUmVzdHJpY3RlZCBDb250ZW50IjsKICAgIGF1dGhfYmFzaWNfdXNlcl9maWxlIC9ldGMvbmdpbngvLnNrYWRpX2F1dGg7CiAgfQogIGxvY2F0aW9uIC9jeWJlcmNoZWYvIHsKICAgIHByb3h5X3Bhc3MgaHR0cDovL2xvY2FsaG9zdDo4MDAwLzsKICAgIHByb3h5X3NldF9oZWFkZXIgSG9zdCAkaG9zdDsKICAgIGF1dGhfYmFzaWMgIlJlc3RyaWN0ZWQgQ29udGVudCI7CiAgICBhdXRoX2Jhc2ljX3VzZXJfZmlsZSAvZXRjL25naW54Ly5za2FkaV9hdXRoOwogIH0KfQo="

# Configure default site
echo $nginx_conf |base64 -d |sudo tee /etc/nginx/sites-available/default

# Configure Nginx proxy Credentials
if [ $default_skadi_passwords = "false" ]; then
  n_user="skadi_$(openssl rand -base64 3)"
  n_pass=$(openssl rand -base64 32)
else
  n_user="skadi"
  n_pass="skadi"
fi
  echo $n_pass | sudo htpasswd -i -c /etc/nginx/.skadi_auth $n_user

# Configure Kibana Credentials
# k_user="kibuser_$(openssl rand -base64 3)"
# k_pass=$(openssl rand -base64 32)
# echo $k_pass | sudo htpasswd -i -c /etc/nginx/.kibana_auth $k_user

# Configure Cerebro Credentials
# c_user="ceruser_$(openssl rand -base64 3)"
# c_pass=$(openssl rand -base64 32)
# echo $c_pass | sudo htpasswd -i -c /etc/nginx/.cerebro_auth $c_user

echo "Installing Cyberchef Docker"
sudo docker run --name cyberchef --restart unless-stopped -d -p 127.0.0.1:8000:8000 mpepping/cyberchef:v8.8.5

sudo systemctl restart nginx
sudo systemctl enable nginx

new_domain="localhost"

echo ""
echo ""
echo ""
echo ""

echo ""
echo "Logstash is installed but not enabled by default"
echo "To enable run the following commands"
echo "    sudo systemctl restart logstash"
echo "    sudo systemctl enable logstash"
echo ""
echo ""
echo "Installed Software Version Checks (Where it is supported)"
/usr/bin/log2timeline.py --version 2>&1 >/dev/null |awk '{ printf "Plaso Version %s\n", $5 }'
/usr/local/bin/cdqr.py --version |awk '{split($0,a,":");printf "%s%s\n", a[1], a[2]}'
echo $cylr_version
docker --version |awk '{split($3,a,",");printf "%s Version %s\n", $1, a[1]}'
echo "ELK Version $(curl --silent -XGET 'localhost:9200' |awk '/number/{print substr($3, 2, length($3)-3)}')"
pip show timesketch |grep Version:|awk '{split($0,a,":");printf "TimeSketch %s%s\n", a[1], a[2]}'
redis-server --version|awk '{ split($3,a, "=");printf "%s Version %s\n", $1, a[2] }'
neo4j --version |awk '{printf "Neo4j Version %s\n", $2}'
echo "Celery Version $(celery --version |awk '{print$1}')"
echo "Cerebro Version $cerebro_version"
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
echo "     - Username: $n_user"
echo "     - Password: $n_pass"
echo ""
echo "  Cerebro"
echo "   - 'http://$new_domain/cerebro'"
echo "     - Username: $n_user"
echo "     - Password: $n_pass"
