#!/bin/bash

echo "Updating OS"
sudo apt -y update
sudo apt -y install wget curl
sudo apt -y dist-upgrade
sudo apt -y autoremove

echo "Updating CDQR"
wget -O /tmp/cdqr.py https://raw.githubusercontent.com/rough007/CDQR/master/src/cdqr.py
chmod a+x /tmp/cdqr.py
sudo mv /tmp/cdqr.py /usr/local/bin/cdqr.py

echo "Updating CyLR"
#Building the CyLR link
LATEST_RELEASE=$(curl -L -s -H 'Accept: application/json' https://github.com/rough007/CyLR/releases/latest)
LATEST_VERSION=$(echo $LATEST_RELEASE | sed -e 's/.*"tag_name":"\([^"]*\)".*/\1/')
ARTIFACT_URL="https://github.com/rough007/CyLR/releases/download/$LATEST_VERSION/CyLR.zip"


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
    echo "Update failed, exiting"
    exit 1
  fi
fi

rm /tmp/CyLR.zip
echo "CyLR successfully updated in /opt/CyLR/"
echo "Update successful"