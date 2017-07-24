#!/bin/bash

echo "Updating OS"
sudo apt-get -y update
sudo apt-get -y dist-upgrade
sudo apt-get -y autoremove

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


echo "Updating Cerebro"
#Building the Cerebro link
LATEST_RELEASE=$(curl -L -s -H 'Accept: application/json' https://github.com/lmenezes/cerebro/releases/latest)
LATEST_VERSION=$(echo $LATEST_RELEASE | sed -e 's/.*"tag_name":"\([^"]*\)".*/\1/')
ZIP_NAME="cerebro"$(echo $LATEST_VERSION | tr v -)".tgz"
ARTIFACT_URL="https://github.com/lmenezes/cerebro/releases/download/$LATEST_VERSION/$ZIP_NAME"

wget $ARTIFACT_URL
CURRENT_VERSION="/opt/"$(ls -d /opt/cerebro*| grep -o "cerebro-.*")
if [ $CURRENT_VERSION != "/opt/" ]
then
  echo "Backing up $CURRENT_VERSION to cerebro.bak.tgz"
  sudo tar -cf cerebro.bak.tgz $CURRENT_VERSION

  echo "Preserving $CURRENT_VERSION/conf/application.conf"
  sudo cp $CURRENT_VERSION/conf/application.conf .

  echo "Removing $CURRENT_VERSON"
  sudo rm -rf $CURRENT_VERSION

else
  echo "No previous version to remove.  Moving on to installation"
fi

echo "Installing Update"
sudo tar -xf $ZIP_NAME -C /opt/

NEW_VERSION="/opt/"$(ls -d /opt/cerebro*| grep -o "cerebro-.*")

if [ $CURRENT_VERSION != "/opt/" ]
then
  echo "Restoring preserved version of $CURRENT_VERSION/conf/application.conf to $NEW_VERSION/conf/application.conf"
  sudo cp application.conf $CURRENT_VERSION/conf/
  sudo rm application.conf
else
  sudo rm $NEW_VERSION/conf/application.conf
  echo '# Secret will be used to sign session cookies, CSRF tokens and for other encryption utilities.
# It is highly recommended to change this value before running cerebro in production.
secret = "ki:s:[[@=Ag?QI`W2jMwkY:eqvrJ]JqoJyi2axj3ZvOv^/KavOT4ViJSv?6YY4[N"

# Application base path
basePath = "/"

# Defaults to RUNNING_PID at the root directory of the app.
# To avoid creating a PID file set this value to /dev/null
#pidfile.path = "/var/run/cerebro.pid"

# Rest request history max size per user
rest.history.size = 50 // defaults to 50 if not specified

# Path of local database file
data.path = "./cerebro.db"

# Authentication
auth = {
  # Example of LDAP authentication
  #type: ldap
    #settings: {
      #url = "ldap://host:port"
      #base-dn = "ou=active,ou=Employee"
      #method  = "simple"
      #user-domain = "domain.com"
    #}
  # Example of simple username/password authentication
  #type: basic
    #settings: {
      #username = "admin"
      #password = "1234"
    #}
}

# A list of known hosts
hosts = [
# Example of host without authentication
  {
    host = "http://localhost:9200"
    name = "CCF-VM"
  }
# Example of host with authentication
  #{
  #  host = "http://some-authenticated-host:9200"
  #  name = "Secured Cluster"
  #  auth = {
  #    username = "username"
  #    password = "secret-password"
  #  }
  #}
]' | sudo tee -a $NEW_VERSION/conf/application.conf > /dev/null
fi
rm $ZIP_NAME

echo "Removing KOPF (if installed)"
sudo /usr/share/elasticsearch/bin/plugin remove kopf

sudo pkill -f /opt/cerebro
sudo $NEW_VERSION/bin/cerebro & > /dev/null
echo "Cerebro Started"
echo "Default access is at: http://\<CCF-VM IP address or localhost\>:9000"

echo "

************************************************************
Updated Cerebro from: $CURRENT_VERSION to $NEW_VERSION

Update Script Finished: BUT YOU'RE NOT DONE YET

Ensure/Add the following lines to the end of /etc/re.local


sleep 30
/opt/cerebro-0.6.5/bin/cerebro >/var/log/cerebro 2>&1 &
tsctl runserver -h 0.0.0.0 -p 5000 >/var/log/timesketch_server 2>&1 &
celery -A timesketch.lib.tasks worker --loglevel=info --uid 1001 >/var/log/timesketch_celery_worker 2>&1 &

exit 0
*************************************************************

"
