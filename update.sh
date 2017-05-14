#!/bin/bash
echo "Updating OS"
sudo apt-get -u upgrade
sudo apt-get -y dist-upgrade

echo "Updating CDQR"
wget https://raw.githubusercontent.com/rough007/CDQR/master/src/cdqr.py
chmod a+x cdqr.py
sudo mv cdqr.py /usr/local/bin/cdqr.py

echo "Updating CyLR"
wget https://github.com/rough007/CyLR/releases/download/v1.3.2/CyLR.zip
rm -rf CyLR/*
unzip CyLR.zip -d CyLR
rm CyLR.zip
