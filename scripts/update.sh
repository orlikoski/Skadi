#!/bin/bash

echo "Updating OS"
sudo apt-get -y update
sudo apt-get -y install wget curl
sudo apt-get -y dist-upgrade
sudo apt-get -y autoremove

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

# If CyLR.exe is on the Desktop, update it
if [ -f /home/skadi/Desktop/CyLR.exe ]; then
    sudo rm /home/skadi/Desktop/CyLR.exe
    sudo cp /opt/CyLR/CyLR/CyLR.exe /home/skadi/Desktop/CyLR.exe
    sudo chown skadi:skadi /home/skadi/Desktop/CyLR.exe
fi

rm /tmp/CyLR.zip
echo "CyLR successfully updated in /opt/CyLR/"
echo "Update successful"
