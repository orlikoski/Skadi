#!/usr/bin/env bash
set -xe
# Update
sudo apt-get update
sudo apt-get dist-upgrade -y

# Install curl
sudo apt-get install apt-transport-https ca-certificates curl software-properties-common python-pip python3-pip -y

# Update pip
sudo -H pip install --upgrade pip && sudo -H pip3 install --upgrade pip


# Disable Swap
sudo swapoff -a

# Add Docker gpg key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

# Install Docker
sudo apt-get install docker-ce -y
sudo systemctl enable docker

# Clean APT
apt-get -y autoremove --purge
apt-get -y clean
apt-get -y autoclean

# Add skadi to docker usergroup
 sudo usermod -aG docker skadi

 # Install Docker-Compose
 sudo -H pip install docker-compose

 # Set the vm.max_map_count kernel setting needs to be set to at least 262144 for production use
 sudo sysctl -w vm.max_map_count=262144
 echo vm.max_map_count=262144 | sudo tee -a /etc/sysctl.conf


# Create needed folders
sudo mkdir -p /opt/skadi/nginx/conf.d
sudo chmod -R skadi:skadi /opt/skadi
sudo mkdir -p /etc/nginx/conf.d

# Copy Nginx configuration files to required locations
sudo cp ./nginx/.skadi_auth /etc/nginx/
sudo cp ./nginx/skadi_default.conf /etc/nginx/conf.d



# Build CyberChef Docker Image
docker build -t cyberchef -f ./cyberchef/Dockerfile ./cyberchef/

# Build TimeSketch Docker Image
docker build -t timesketch -f ./timesketch/docker/Dockerfile ./timesketch/

# Deploy all the things
docker-compose up -d
