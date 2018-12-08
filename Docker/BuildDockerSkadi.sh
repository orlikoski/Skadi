#!/usr/bin/env bash
set -xe
# Update
sudo apt-get update
sudo apt-get dist-upgrade -y

# Install deps
sudo apt-get install apt-transport-https ca-certificates curl software-properties-common python-pip python3-pip psycopg2 unzip vim htop -y

# Update pip
sudo -H pip install pip==9.0.3
#sudo -H pip install --upgrade pip

# Disable Swap
sudo swapoff -a

# Add Docker gpg key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

# Add Plaso repository
sudo add-apt-repository ppa:gift/stable -y

# Install Docker and Plaso
sudo apt-get update
sudo apt-get install docker-ce python-plaso plaso-tools -y
sudo systemctl enable docker

# Clean APT
sudo apt-get -y autoremove --purge
sudo apt-get -y clean
sudo apt-get -y autoclean

# Add skadi to docker usergroup
sudo usermod -aG docker skadi

# Install Docker-Compose
sudo -H pip install docker-compose

# Set the vm.max_map_count kernel setting needs to be set to at least 262144 for production use
sudo sysctl -w vm.max_map_count=262144
echo vm.max_map_count=262144 | sudo tee -a /etc/sysctl.conf

# Create needed folders
sudo mkdir -p /opt/skadi/CyLR
sudo chown -R skadi:skadi /opt/skadi
sudo mkdir -p /etc/nginx/conf.d

# Copy Nginx configuration files to required locations
sudo cp ./nginx/.skadi_auth /etc/nginx/
sudo cp ./nginx/skadi_default.conf /etc/nginx/conf.d

# Build CyberChef Docker Image
sudo docker build -t cyberchef -f ./cyberchef/Dockerfile ./cyberchef/

# Install TimeSketch on host (needed for psort -o timesketch)
# sudo -H pip install timesketch --ignore-installed PyYAML

# Deploy all the things
sudo docker-compose up -d


# Install Celery
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


# Install Gunicorn and TimeSketch
sudo -H pip install timesketch
# sudo -H pip install gunicorn

# Configure TimeSketch
# Set Credentials
SECRET_KEY="$(openssl rand -base64 32 | sha256sum)"
SKADI_USER="skadi"
SKADI_PASSWORD="skadi"
POSTGRES_USER="timesketch"
psql_pw=$(openssl rand -base64 32 | sha256sum)
neo4juser='neo4j'
neo4jpassword=$(openssl rand -base64 32)

# Write Creds to .env file for All Dockers
echo "TIMESKETCH_USER=$SKADI_USER" > ./.env
echo "TIMESKETCH_PASSWORD=$SKADI_PASSWORD" >> ./.env
echo "POSTGRES_USER=$POSTGRES_USER" >> ./.env
echo "POSTGRES_PASSWORD=$psql_pw" >> ./.env
echo "NEO4J_USER"=$neo4juser >> ./.env
echo "NEO4J_PASSWORD"=$neo4jpassword >> ./.env


# Write TimeSketch config file on host for each TS Docker to use
sudo cp /usr/local/share/timesketch/timesketch.conf /etc/
sudo sed -i "s@SECRET_KEY = u'<KEY_GOES_HERE>'@SECRET_KEY = u'$SECRET_KEY'@g" /etc/timesketch.conf
sudo sed -i "s@<USERNAME>\:<PASSWORD>@$POSTGRES_USER\:$psql_pw@g" /etc/timesketch.conf
sudo sed -i "s@NEO4J_USERNAME = u'neo4j'@NEO4J_USERNAME = u'$neo4juser'@g" /etc/timesketch.conf
sudo sed -i "s@NEO4J_PASSWORD = u'<N4J_PASSWORD>'@NEO4J_PASSWORD = u'$neo4jpassword'@g" /etc/timesketch.conf
sudo sed -i "s/UPLOAD_ENABLED = False/UPLOAD_ENABLED = True/g" /etc/timesketch.conf
sudo sed -i "s/GRAPH_BACKEND_ENABLED = False/GRAPH_BACKEND_ENABLED = True/g" /etc/timesketch.conf

tsctl add_user -u "$SKADI_USER" -p "$SKADI_PASSWORD"
sudo useradd -r -s /bin/false timesketch


timesketch_service="W1VuaXRdCkRlc2NyaXB0aW9uPVRpbWVTa2V0Y2ggU2VydmljZQpBZnRlcj1uZXR3b3JrLnRhcmdldAoKW1NlcnZpY2VdClVzZXI9dGltZXNrZXRjaApHcm91cD10aW1lc2tldGNoCkV4ZWNTdGFydD0vdXNyL2xvY2FsL2Jpbi9ndW5pY29ybiAtLXdvcmtlcnMgNCAtLWJpbmQgMTI3LjAuMC4xOjUwMDAgdGltZXNrZXRjaC53c2dpCgpbSW5zdGFsbF0KV2FudGVkQnk9bXVsdGktdXNlci50YXJnZXQK"
echo $timesketch_service |base64 -d | sudo tee /etc/systemd/system/timesketch.service
sudo chmod g+w /etc/systemd/system/timesketch.service
sudo systemctl daemon-reload
sudo systemctl restart timesketch.service
sudo systemctl enable timesketch.service


# # Build TimeSketch Docker Image
# rm -rf ./timesketch
# git clone https://github.com/google/timesketch.git
# sudo docker build -t timesketch -f ./timesketch/docker/Dockerfile ./timesketch/

# git clone https://github.com/google/timesketch.git
# cd timesketch/
# sudo -H pip install . --upgrade




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
