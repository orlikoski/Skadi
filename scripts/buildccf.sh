#!/bin/bash
# Set Hostname to ccf-vm

newhostname='ccf-vm'
oldhostname=$(</etc/hostname)
sudo hostname $newhostname >/dev/null 2>&1
sudo sed -i "s/$oldhostname/$newhostname/g" /etc/hosts >/dev/null 2>&1
echo ccf-vm |sudo tee /etc/hostname >/dev/null 2>&1
sudo systemctl restart systemd-logind.service >/dev/null 2>&1

# Install dependancies: 
sudo sed -i 's/deb cdrom/#deb cdrom/g' /etc/apt/sources.list
sudo apt update -y
sudo apt dist-upgrade -y
sudo apt install -y vim openssh-server curl software-properties-common unzip htop

sudo add-apt-repository ppa:gift/stable -y
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" -y

sudo apt update -y
sudo apt dist-upgrade -y
sudo apt install -y python-software-properties python-plaso plaso-tools
sudo apt autoremove -y

#Install and Configure Elasticsearch
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
sudo apt install apt-transport-https -y
echo "deb https://artifacts.elastic.co/packages/6.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-6.x.list
sudo add-apt-repository ppa:webupd8team/java -y
sudo apt-get update -y
echo debconf shared/accepted-oracle-license-v1-1 select true | sudo debconf-set-selections
echo debconf shared/accepted-oracle-license-v1-1 seen true | sudo debconf-set-selections
sudo apt-get install elasticsearch oracle-java8-installer -y

sudo sed -i 's/#network.host\: 192.168.0.1/network.host\: localhost/g' /etc/elasticsearch/elasticsearch.yml
sudo systemctl daemon-reload
sudo systemctl restart elasticsearch
sudo systemctl enable elasticsearch

# Install Redis
sudo add-apt-repository ppa:chris-lea/redis-server -y
sudo apt update -y
sudo apt install redis-server -y
sudo systemctl daemon-reload
sudo systemctl restart redis-server
sudo systemctl enable redis-server

# Install and Configure Neo4j
neo4juser='neo4j'
neo4jpassword=$(openssl rand -base64 32)
wget -O - https://debian.neo4j.org/neotechnology.gpg.key | sudo apt-key add -
echo 'deb http://debian.neo4j.org/repo stable/' | sudo tee -a /etc/apt/sources.list.d/neo4j.list
sudo apt update -y
sudo apt install neo4j -y
sudo /usr/bin/neo4j-admin set-initial-password $neo4jpassword
sudo systemctl daemon-reload
sudo systemctl restart neo4j
sudo systemctl enable neo4j

# sudo mkdir /var/run/neo4j/
# sudo chmod 666  /var/run/neo4j/
# neo4j-admin set-initial-password cdqr
# sudo neo4j start

# Install and Configure Kibana
sudo apt install kibana -y
sudo sed -i 's/#server.host\:/server.host\:/g' /etc/kibana/kibana.yml
sudo systemctl daemon-reload
sudo systemctl restart kibana
sudo systemctl enable kibana


# Install and Configure TimeSketch
SECRET_KEY=$(openssl rand -base64 32 | sha256sum)
psql_pw=$(openssl rand -base64 32 | sha256sum)

sudo mkdir -p /etc/elasticsearch/scripts
sudo wget -O /etc/elasticsearch/scripts/add_label.groovy https://raw.githubusercontent.com/google/timesketch/master/contrib/add_label.groovy
sudo wget -O /etc/elasticsearch/scripts/toggle_label.groovy https://raw.githubusercontent.com/google/timesketch/master/contrib/toggle_label.groovy
sudo apt-get install postgresql -y
sudo apt-get install python-psycopg2 -y

echo "local all timesketch md5"|sudo tee -a /etc/postgresql/9.5/main/pg_hba.conf
sudo systemctl restart postgresql.service
echo "create user timesketch with password '$psql_pw';" | sudo -u postgres psql || true
echo "create database timesketch owner timesketch;" | sudo -u postgres psql || true

sudo apt install python-pip python-dev libffi-dev -y
sudo -H pip install --upgrade pip
sudo -H pip install timesketch

sudo cp /usr/local/share/timesketch/timesketch.conf /etc/
sudo sed -i "s@SECRET_KEY = u''@SECRET_KEY = u'$SECRET_KEY'@g" /etc/timesketch.conf
sudo sed -i "s@<USERNAME>\:<PASSWORD>@timesketch\:$psql_pw@g" /etc/timesketch.conf
sudo sed -i "s/UPLOAD_ENABLED = False/UPLOAD_ENABLED = True/g" /etc/timesketch.conf
sudo sed -i "s/GRAPH_BACKEND_ENABLED = False/GRAPH_BACKEND_ENABLED = True/g" /etc/timesketch.conf
sudo sed -i "s@NEO4J_USERNAME = u''@NEO4J_USERNAME = u'$neo4juser'@g" /etc/timesketch.conf
sudo sed -i "s@NEO4J_PASSWORD = u''@NEO4J_PASSWORD = u'$neo4jpassword'@g" /etc/timesketch.conf
sudo sed -i "s/GRAPH_BACKEND_ENABLED = False/GRAPH_BACKEND_ENABLED = True/g" /etc/timesketch.conf

tsctl add_user -u cdqr -p Changemen0w\!

timesketch_service="W1VuaXRdCkRlc2NyaXB0aW9uPVRpbWVTa2V0Y2ggU2VydmljZQpBZnRlcj1uZXR3b3JrLnRhcmdldAoKW1NlcnZpY2VdCkV4ZWNTdGFydD0vdXNyL2xvY2FsL2Jpbi90c2N0bCBydW5zZXJ2ZXIgLWggMC4wLjAuMCAtcCA1MDAwIC0tdGhyZWFkZWQgLS1wYXNzdGhyb3VnaC1lcnJvcnMKCltJbnN0YWxsXQpXYW50ZWRCeT1tdWx0aS11c2VyLnRhcmdldAo="

sudo useradd -r -s /bin/false timesketch

echo $timesketch_service |base64 -d | sudo tee /etc/systemd/system/timesketch.service
sudo chmod g+w /etc/systemd/system/timesketch.service
sudo systemctl daemon-reload
sudo systemctl restart timesketch.service
sudo systemctl enable timesketch.service



curl -sSL https://raw.githubusercontent.com/rough007/CCF-VM/master/scripts/update.sh |bash
echo ""
echo ""
echo "System Health Checks"
# system health checks
declare -a services=('elasticsearch' 'postgresql' 'celery' 'neo4j' 'redis' 'kibana' 'timesketch')
# Ensure all Services are started
for item in "${services[@]}"
do
	echo "  Bringing up $item"
		sudo systemctl restart $item
			sleep 1
			done

			echo ""

			for item in "${services[@]}"
			do
				echo "  $item service is: $(systemctl is-active $item)"
			done

echo ""
echo "Verifying versions of Plaso and CDQR"
/usr/bin/log2timeline.py --version
/usr/local/bin/cdqr.py --version
exec bash

