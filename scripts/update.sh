#!/bin/bash
# Set the version of CDQR docker
cdqr_version=${CDQR_VERSION:-"4.4.0"}

# Set the installation branch
install_branch=${INSTALL_BRANCH:-"master"}

echo "Updating OS"
sudo apt-get -y update
sudo apt-get -y install wget curl
sudo DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" dist-upgrade
sudo apt-get -y autoremove

# Installs and Configures CDQR and CyLR
echo "Updating CDQR"
echo "Downloading cdqr docker script into /usr/local/bin/cdqr"
sudo curl -o /usr/local/bin/cdqr "https://raw.githubusercontent.com/orlikoski/Skadi/$install_branch/scripts/cdqr"
sudo chmod +x /usr/local/bin/cdqr
echo "Downloading aorlikoski/CDQR:$cdqr_version "
sudo docker pull "aorlikoski/cdqr:$cdqr_version"

echo "Updating CyLR"
# Building the CyLR link
cylr_files=( "CyLR_linux-x64.zip" "CyLR_osx-x64.zip" "CyLR_win-x64.zip" "CyLR_win-x86.zip")
LATEST_RELEASE=$(curl -L -s -H 'Accept: application/json' https://github.com/orlikoski/CyLR/releases/latest)
LATEST_VERSION=$(echo $LATEST_RELEASE | sed -e 's/.*"tag_name":"\([^"]*\)".*/\1/')
ARTIFACT_URL="https://github.com/orlikoski/CyLR/releases/download/$LATEST_VERSION/"

# Remove old versions
if [ -f /opt/CyLR/CyLR.exe ]; then
    sudo rm /opt/CyLR/CyLR.exe
fi
if [ -f /home/skadi/Desktop/CyLR.exe ]; then
    sudo rm /home/skadi/Desktop/CyLR.exe
fi

for cylrzip in "${cylr_files[@]}"
do
  if [ ! -d "/opt/CyLR" ]; then
    sudo mkdir /opt/CyLR/
    sudo chmod 777 /opt/CyLR
  else
    sudo rm -rf /opt/CyLR/$cylrzip
  fi
  wget -O "/opt/CyLR/$cylrzip" "$ARTIFACT_URL/$cylrzip" > /dev/null 2>&1
  if [ $? -ne 0 ]; then
    echo "CyLR Download of $cylrzip failed"
  else
      if [ -d "CyLR/" ]; then
        sudo rm -rf CyLR/
      fi
      echo "$cylrzip downloaded into /opt/CyLR/"
  fi
done
# If Skadi Desktop exists place link to CyLR folder on it
if [ -d /home/skadi/Desktop ]; then
    sudo ln -s /opt/CyLR /home/skadi/Desktop/CyLR
    sudo chown -h skadi:skadi /home/skadi/Desktop/CyLR
fi

unzip -o /opt/CyLR/CyLR_linux-x64.zip -d /tmp/ > /dev/null 2>&1
cylr_version=$(/tmp/CyLR --version |grep Version)
rm /tmp/CyLR > /dev/null 2>&1
echo "All CyLR Files Downloaded"
echo "Updated to $cylr_version"

echo "Update successful"
