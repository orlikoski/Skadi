#!/bin/bash

echo "Installing pip3 for Python3 if not installed"
sudo apt install python3-pip
echo "Getting Python dependencies"
sudo -H pip3 install -r requirements.txt
