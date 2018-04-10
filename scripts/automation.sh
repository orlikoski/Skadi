#!/bin/bash
echo "Installing gRPC automation"
# Create Automation user and group
echo "Creating new group 'automationadmmin' and new user 'ottomate' to be used for all automation functions"
sudo addgroup automationadmin # Create automation group
sudo adduser ottomate --disabled-password --gecos "" --shell /bin/bash # Create automation user: follow prompts to enter user information
sudo usermod -aG automationadmin ottomate # Add user to automation group

# Create .ssh directory and authorized_keys file for the new user
sudo mkdir -p /home/ottomate/.ssh/
sudo touch /home/ottomate/.ssh/authorized_keys
sudo chmod 700 /home/ottomate/.ssh/
sudo chown -R ottomate:ottomate /home/ottomate/.ssh
sudo chmod 644 /home/ottomate/.ssh/authorized_keys

# Getting Python dependencies
sudo apt install python3-pip -y # Install pip for python3
sudo -H pip3 install --upgrade pip # Upgrade pip for python3
sudo -H pip3 install requests botocore==1.8.36 boto3 pyyaml # Python3 requirements
sudo -H python -m pip install grpcio grpcio-tools # Python2 requirements

# Download and place files in the correct places on server
automation_files=("rc.py" "logging.yaml")
grpc_files=("rc_client.py" "rc_server.py" "rc.proto") 
automation_dir="/var/lib/automation"
logging_dir="/var/log/automation"
logging_file="/var/log/automation/skadi_automation.log"

# Create automation directory where all automation files will run from
sudo mkdir -p "$automation_dir"

# Create directory and set permissions for automation logging
sudo mkdir -p "$logging_dir"
sudo touch "$logging_file"
sudo chown ottomate:ottomate "$logging_file"
sudo chmod 644 "$logging_file"

# Download and install GRPC files
for i in "${grpc_files[@]}"
do
    wget -O "/tmp/$i" "https://raw.githubusercontent.com/orlikoski/CCF-VM/$branch/scripts/grpc/$i"
    sudo mv "/tmp/$i" "$automation_dir/"
    sudo chown root:root "$automation_dir/$i"
    sudo chmod 644 "$automation_dir/$i"
done
sudo python -m grpc_tools.protoc -I"$automation_dir/" --python_out="$automation_dir/" --grpc_python_out="$automation_dir/" "$automation_dir/rc.proto" # Compile proto file for GRPC API

# Setup GRPC Logging
sudo mkdir -p /var/log/ # create path if not there
sudo touch /var/log/ccfvm.log # create initial file
sudo chmod 666 /var/log/ccfvm.log # adjust permission, can change to 644 once service is built
sudo chown ottomate:ottomate /var/log/ccfvm.log # change ownershipt to ottomate user

# Download and install Automation files
for i in "${automation_files[@]}"
do
    wget -O "/tmp/$i" "https://raw.githubusercontent.com/orlikoski/CCF-VM/master/scripts/$i"
    sudo mv "/tmp/$i" "$automation_dir/"
    sudo chown root:root "$automation_dir/$i"
    sudo chmod 644 "$automation_dir/$i"
done
sudo chmod 755 "$automation_dir/rc.py" # Make this executable


# Configure gRPC as a service named ccfvm_grpc_service
ccfvm_grpc="W1VuaXRdCkRlc2NyaXB0aW9uPUNDRi1WTSBBdXRvbWF0aW9uIFNlcnZpY2UKQWZ0ZXI9bmV0d29yay50YXJnZXQKCltTZXJ2aWNlXQpVc2VyPW90dG9tYXRlCkdyb3VwPW90dG9tYXRlCkV4ZWNTdGFydD0vdXNyL2Jpbi9weXRob24gL3Zhci9saWIvYXV0b21hdGlvbi9yY19zZXJ2ZXIucHkKCltJbnN0YWxsXQpXYW50ZWRCeT1tdWx0aS11c2VyLnRhcmdldAo="
echo $ccfvm_grpc |base64 -d | sudo tee /etc/systemd/system/ccfvm_grpc.service
sudo chmod g+w /etc/systemd/system/ccfvm_grpc.service
sudo systemctl daemon-reload
sudo systemctl restart ccfvm_grpc.service
sudo systemctl enable ccfvm_grpc.service
