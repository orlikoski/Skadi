#!/usr/bin/env bash
set -xe
# Update
sudo apt-get update
sudo apt-get dist-upgrade -y

# Install deps
sudo apt-get install apt-transport-https ca-certificates curl software-properties-common python-pip python3-pip unzip vim htop -y

# Update pip
sudo -H pip install --upgrade pip && sudo -H pip3 install --upgrade pip

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

# Build TimeSketch Docker Image
rm -rf ./timesketch
git clone https://github.com/google/timesketch.git
sudo docker build -t timesketch -f ./timesketch/docker/Dockerfile ./timesketch/

# Install TimeSketch on host (needed for psort -o timesketch)
sudo -H pip2 install timesketch

# Deploy all the things
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
