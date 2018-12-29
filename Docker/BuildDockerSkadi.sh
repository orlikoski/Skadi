#!/usr/bin/env bash
set -e
# Set Credentials
SECRET_KEY=$(openssl rand -base64 32 |sha256sum | sed 's/ //g')
POSTGRES_USER="timesketch"
psql_pw=$(openssl rand -base64 32 |sha256sum | sed 's/ //g')
neo4juser='neo4j'
neo4jpassword=$(openssl rand -base64 32 |sha256sum | sed 's/ //g')
TIMESKETCH_USER="skadi"
TIMESKETCH_PASSWORD="skadi"
GRAFANA_USER="skadi"
GRAFANA_PASSWORD="skadi"

# Create Skadi user
SKADI_USER="skadi"
SKADI_PASS="skadi"
SKADI_USER_HOME="/home/$SKADI_USER"

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

# Update
sudo apt-get update && sudo apt-get dist-upgrade -y

# Install deps
sudo apt-get install apt-transport-https ca-certificates curl software-properties-common python-pip glances unzip vim htop -y

# Ensure pip is on 9.0.3 for installation
sudo -H pip install pip==9.0.3 --no-cache-dir

# Disable Swap
sudo swapoff -a

# Create CyLR directory
sudo mkdir /opt/CyLR/
sudo chmod 777 /opt/CyLR

# Add Docker gpg key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

# Add Plaso repository
sudo add-apt-repository ppa:gift/stable -y

# Install Docker and Plaso
sudo apt-get update
sudo apt-get install docker-ce python-plaso plaso-tools python-psycopg2  -y
sudo systemctl enable docker

# Clean APT
sudo apt-get -y autoremove --purge
sudo apt-get -y clean
sudo apt-get -y autoclean

# Add skadi to docker usergroup
sudo usermod -aG docker $SKADI_USER

# Install Docker-Compose
sudo curl -L "https://github.com/docker/compose/releases/download/1.23.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo curl -L https://raw.githubusercontent.com/docker/compose/1.23.1/contrib/completion/bash/docker-compose -o /etc/bash_completion.d/docker-compose

# Set the vm.max_map_count kernel setting needs to be set to at least 262144 for production use
sudo sysctl -w vm.max_map_count=262144
echo vm.max_map_count=262144 | sudo tee -a /etc/sysctl.conf

# Create needed folders
sudo mkdir -p /opt/skadi/CyLR
sudo chown -R skadi:skadi /opt/skadi
sudo mkdir -p /etc/nginx/conf.d
sudo mkdir -p /usr/share/nginx/html

# Copy Nginx configuration files to required locations
sudo git clone https://github.com/orlikoski/Skadi.git /opt/Skadi
sudo cp /opt/Skadi/Docker/nginx/.skadi_auth /etc/nginx/
sudo cp /opt/Skadi/Docker/nginx/skadi_default.conf /etc/nginx/conf.d
sudo cp -r /opt/Skadi/Docker/nginx/www/* /usr/share/nginx/html

# Install TimeSketch on the Host (required for psort.py to output in timesketch format)
sudo -H pip install timesketch

# Write TS and Postgres creds to .env file
cd /opt/Skadi/Docker/
echo TIMESKETCH_USER=$TIMESKETCH_USER > ./.env
echo TIMESKETCH_PASSWORD=$TIMESKETCH_PASSWORD >> ./.env
echo POSTGRES_USER=$POSTGRES_USER >> ./.env
echo POSTGRES_PASSWORD=$psql_pw >> ./.env
echo NEO4J_PASSWORD=$neo4neo4jpassword >> ./.env

# Configure /etc/hosts file so the host can use same names for each service as the TimeSketch Dockers
echo 127.0.0.1       elasticsearch |sudo tee -a /etc/hosts
echo 127.0.0.1       postgres |sudo tee -a /etc/hosts
echo 127.0.0.1       neo4j |sudo tee -a /etc/hosts
echo 127.0.0.1       redis |sudo tee -a /etc/hosts

# Write TimeSketch config file on host
sudo cp /usr/local/share/timesketch/timesketch.conf /etc/
sudo sed -i "s@SECRET_KEY = u'<KEY_GOES_HERE>'@SECRET_KEY = u'$SECRET_KEY'@g" /etc/timesketch.conf
sudo sed -i "s@<USERNAME>\:<PASSWORD>@$POSTGRES_USER\:$psql_pw@g" /etc/timesketch.conf
sudo sed -i "s@NEO4J_USERNAME = u'neo4j'@NEO4J_USERNAME = u'$neo4juser'@g" /etc/timesketch.conf
sudo sed -i "s@NEO4J_PASSWORD = u'<N4J_PASSWORD>'@NEO4J_PASSWORD = u'$neo4jpassword'@g" /etc/timesketch.conf
sudo sed -i "s/UPLOAD_ENABLED = False/UPLOAD_ENABLED = True/g" /etc/timesketch.conf
sudo sed -i "s/GRAPH_BACKEND_ENABLED = False/GRAPH_BACKEND_ENABLED = True/g" /etc/timesketch.conf
sudo sed -i "s#@localhost/timesketch#@postgres/timesketch#g" /etc/timesketch.conf
sudo sed -i "s/ELASTIC_HOST = u'127.0.0.1'/ELASTIC_HOST = u'elasticsearch'/g" /etc/timesketch.conf
sudo sed -i "s@'redis://127.0.0.1:6379'@'redis://redis:6379'@g" /etc/timesketch.conf
sudo sed -i "s/NEO4J_HOST = u'127.0.0.1'/NEO4J_HOST = u'neo4j'/g" /etc/timesketch.conf

# To build TimeSketch and CyberChef Docker Images Locally, uncomment the following lines
# sudo docker build -t aorlikoski/skadi_timesketch:1.0 ./timesketch/
# sudo docker build -t aorlikoski/skadi_cyberchef:1.0 ./cyberchef/

# Deploy the Skadi solution defined in ./docker-compose.yml
sudo docker-compose up -d

# Create a template in ES that sets the number of replicas for all indexes to 0
echo "Waiting for ElasticSearch service to respond to requests"
until $(curl --output /dev/null --silent --head --fail http://localhost:9200); do
    printf '.'
    sleep 5
done
echo "Setting the ElasticSearch default number of replicas to 0"

curl -XPUT 'localhost:9200/_template/number_of_replicas' \
    -d '{"template": "*","settings": {"number_of_replicas": 0}}' \
    -H'Content-Type: application/json'

# The TimeSketch container needs to be running before continuing and this
# requires the other containers to be up and running too. This can take time
# so this loop ensures all the parts are running and timesketch is responding
# to web requets before continuing
echo "Waiting for TimeSketch to become available"
echo "Press CTRL-C at any time to stop installation"
until $(curl --output /dev/null --silent --head --fail http://localhost/timesketch); do
    echo "No response, restarting the TimeSketch container and waiting 10 seconds to try again"
    sudo docker restart timesketch
    sleep 10
done
echo "TimeSketch available. Continuing"

# Install Glances as a Service
glances_service="W1VuaXRdCkRlc2NyaXB0aW9uPUdsYW5jZXMKQWZ0ZXI9bmV0d29yay50YXJnZXQKCltTZXJ2aWNlXQpFeGVjU3RhcnQ9L3Vzci9iaW4vZ2xhbmNlcyAtdwpSZXN0YXJ0PW9uLWFib3J0CgpbSW5zdGFsbF0KV2FudGVkQnk9bXVsdGktdXNlci50YXJnZXQK"
echo $glances_service |base64 -d | sudo tee /etc/systemd/system/glances.service
sudo chmod g+w /etc/systemd/system/glances.service
sudo systemctl daemon-reload
sudo systemctl restart glances
sudo systemctl enable glances

# Install Grafana for Monitoring
git clone https://github.com/orlikoski/skadi_dockprom.git
cd skadi_dockprom

# Write Grafana login creds to .env file
echo ADMIN_USER=$GRAFANA_USER > ./.env
echo ADMIN_PASSWORD=$GRAFANA_PASSWORD >> ./.env

# This uses the docker-compose.yml found in the skadi_dockprom repo
sudo docker-compose up -d

# Installs and Configures CDQR and CyLR
echo "Updating CDQR"
wget -O /tmp/cdqr.py https://raw.githubusercontent.com/orlikoski/CDQR/master/src/cdqr.py
chmod a+x /tmp/cdqr.py
sudo mv /tmp/cdqr.py /usr/local/bin/cdqr.py
echo "CDQR is in /usr/local/bin/cdqr.py"

echo "Updating CyLR"
cylr_files=( "CyLR_linux-x64.zip" "CyLR_osx-x64.zip" "CyLR_win-x64.zip" "CyLR_win-x86.zip")
LATEST_RELEASE=$(curl -L -s -H 'Accept: application/json' https://github.com/orlikoski/CyLR/releases/latest)
LATEST_VERSION=$(echo $LATEST_RELEASE | sed -e 's/.*"tag_name":"\([^"]*\)".*/\1/')
ARTIFACT_URL="https://github.com/orlikoski/CyLR/releases/download/$LATEST_VERSION/"

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

# Enable and Configure UFW Firewall
echo "Enabling UFW firewall to only allow OpenSSH and Ngninx Full"
sudo ufw allow 80
sudo ufw allow 443
sudo ufw allow 'OpenSSH'
sudo ufw --force enable
