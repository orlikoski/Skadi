#!/bin/bash
# Download and place files in the correct places on server
automation_files=("rc.py" "logging.yaml")
grpc_files=("rc_client.py" "rc_server.py" "rc.proto") 
automation_dir="/var/lib/automation"
logging_dir="/var/log/automation"
logging_file="/var/log/automation/skadi_automation.log"

echo "Installing Skadi automation"
echo "This installation will do the following:"
echo "  - Create new group 'automationadmin'"
echo "  - Create new user 'ottomate' and add to 'automationadmin' group"
echo "    - 'ottomate' is disabled from authenticating with password (must use key pair)"
echo "    - 'ottomate' is used to execute all items related to automation (gRPC and SSH options)"
echo "  - Install all Skadi automation files to '/var/lib/automation'"
echo "  - Setup automation log file in $logging_file"
echo "  - Configure Systemd service 'grpc_automation.service' to control the gRPC automation"
echo "  - Add UFW firewall rule to allow port 10101 from anywhere to use with gRPC service"
echo ""
echo "*********** WARNING ***********"
echo "root or sudo privileges are required for this installation"
echo "*********** WARNING ***********"
echo ""
read -n 1 -r -s -p "Press any key to continue... or CTRL+C to exit (nothing has been installed)"
echo ""
echo ""


# Create Automation user and group
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
    wget -O "/tmp/$i" "https://raw.githubusercontent.com/orlikoski/Skadi/master/scripts/grpc/$i"
    sudo mv "/tmp/$i" "$automation_dir/"
    sudo chown root:root "$automation_dir/$i"
    sudo chmod 644 "$automation_dir/$i"
done
sudo python -m grpc_tools.protoc -I"$automation_dir/" --python_out="$automation_dir/" --grpc_python_out="$automation_dir/" "$automation_dir/rc.proto" # Compile proto file for GRPC API

# Setup GRPC Logging
sudo mkdir -p "$automation_dir" # create path if not there
sudo touch "$logging_file" # create initial file
sudo chmod 666 "$logging_file" # adjust permission, can change to 644 once service is built
sudo chown ottomate:ottomate "$logging_file" # change ownershipt to ottomate user

# Download and install Automation files
for i in "${automation_files[@]}"
do
    wget -O "/tmp/$i" "https://raw.githubusercontent.com/orlikoski/Skadi/master/scripts/$i"
    sudo mv "/tmp/$i" "$automation_dir/"
    sudo chown root:root "$automation_dir/$i"
    sudo chmod 644 "$automation_dir/$i"
done
sudo chmod 755 "$automation_dir/rc.py" # Make this executable


# Configure gRPC as a service named grpc_automation
skadi_grpc="W1VuaXRdCkRlc2NyaXB0aW9uPWdSUEMgQXV0b21hdGlvbiBTZXJ2aWNlCkFmdGVyPW5ldHdvcmsudGFyZ2V0CgpbU2VydmljZV0KVXNlcj1vdHRvbWF0ZQpHcm91cD1vdHRvbWF0ZQpFeGVjU3RhcnQ9L3Vzci9iaW4vcHl0aG9uIC92YXIvbGliL2F1dG9tYXRpb24vcmNfc2VydmVyLnB5CgpbSW5zdGFsbF0KV2FudGVkQnk9bXVsdGktdXNlci50YXJnZXQK"
echo $skadi_grpc |base64 -d | sudo tee /etc/systemd/system/grpc_automation.service
sudo chmod g+w /etc/systemd/system/grpc_automation.service
sudo systemctl daemon-reload
sudo systemctl restart grpc_automation.service
sudo systemctl enable grpc_automation.service

# Open port in UFW firewall
sudo ufw allow 10101

rc_client_usage = "rc_client.py <server IP address or routable domain name> <commands to send to rc_server.py>"
echo ""
echo ""
echo "Installation complete"
echo "  - Refer to Skadi wiki for remaining items required to use a RSA keypair for SSH based automation"
echo "  - Use 'sudo systemctl status grpc_automation' to verify service is running"
echo "  - Use 'tail -f $logging_file' to check the automation engine ('rc.py') logs"
echo "  - Use 'sudo journalctl -f -u grpc_automation' to check the gRPC automation service ('rc_server.py') logs"
echo ""
echo "gRPC Automation Instructions"
echo "  - Use the files in '$automation_dir' and specifically '$automation_dir/rc_client.py' to send automation commands to Skadi"
echo "  - Usage: /usr/bin/python $rc_client_usage"
echo ""
echo "To verify Automation is working run the following:"
echo "/usr/bin/python /var/lib/automation/rc_client.py localhost -h"