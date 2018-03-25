#!/bin/bash
# Create Automation user and group
echo "Creating new group `automationadmmin` and new user `ottomate` to be used for all automation functions"
echo "Please enter user information when prompted"
sudo addgroup automationadmin # Create automation group
sudo adduser ottomate --disabled-password --shell /bin/bash # Create automation user: follow prompts to enter user information
sudo usermod -aG automationadmin ottomate # Add user to automation group

# Create .ssh directory for the new user
sudo mkdir -p /home/ottomate/.ssh/
sudo chmod 700 /home/ottomate/.ssh/

# Getting Python dependencies
sudo apt install python3-pip -y # Install pip for python3
sudo -H pip3 install --upgrade pip # Upgrade pip for python3
sudo -H pip3 install requests botocore==1.8.36 boto3 pyyaml # Python3 requirements
sudo -H python -m pip install grpcio grpcio-tools # Python2 requirements

# Download and place files in the correct places on server
automation_files=("rc.py" "logging.yaml")
grpc_files=("rc_client.py" "rc_server.py" "rc.proto")
automation_dir="/var/lib/automation"

# Create automation directory where all automation files will run from
sudo mkdir -p "$automation_dir"

# Download and install GRPC files
for i in "${grpc_files[@]}"
do
    wget -O "/tmp/$i" "https://raw.githubusercontent.com/rough007/CCF-VM/automation/scripts/grpc/$i"
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
    wget -O "/tmp/$i" "https://raw.githubusercontent.com/rough007/CCF-VM/automation/scripts/$i"
    sudo mv "/tmp/$i" "$automation_dir/"
    sudo chown root:root "$automation_dir/$i"
    sudo chmod 644 "$automation_dir/$i"
done
sudo chmod 755 "$automation_dir/rc.py" # Make this executable


