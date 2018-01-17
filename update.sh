#!/bin/bash

echo "Updating OS"
sudo apt -y update
sudo apt -y dist-upgrade
sudo apt -y autoremove

echo "Updating CDQR"
wget https://raw.githubusercontent.com/rough007/CDQR/master/src/cdqr.py
chmod a+x cdqr.py
sudo mv cdqr.py /usr/local/bin/cdqr.py

echo "Updating CyLR"
#Building the CyLR link
LATEST_RELEASE=$(curl -L -s -H 'Accept: application/json' https://github.com/rough007/CyLR/releases/latest)
LATEST_VERSION=$(echo $LATEST_RELEASE | sed -e 's/.*"tag_name":"\([^"]*\)".*/\1/')
ARTIFACT_URL="https://github.com/rough007/CyLR/releases/download/$LATEST_VERSION/CyLR.zip"

wget $ARTIFACT_URL
rm -rf CyLR/*
unzip CyLR.zip -d CyLR
rm CyLR.zip
