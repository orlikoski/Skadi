#!/bin/bash
# Create Automation user and group
sudo addgroup automationadmin # Create automation group
sudo adduser ottomate --disabled-password --shell /bin/bash # Create automation user: follow prompts to enter user information
sudo usermod -aG automationadmin ottomate # Add user to automation group

echo "Installing pip3 for Python3 if not installed"
sudo apt install python3-pip -y
sudo -H pip3 install --upgrade pip
echo "Getting Python dependencies"
sudo -H pip3 install -r requirements.txt
sudo mv rc.py /var/lib/automation/
sudo mv logging.yaml /var/lib/automation/
sudo mkdir -p /var/log/
sudo touch /var/log/ccfvm.log
sudo chmod 666 /var/log/ccfvm.log
sudo chown ottomate:ottomate /var/log/ccfvm.log
