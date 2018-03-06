#!/bin/bash
# Set Hostname to ccf-vm

newhostname='ccf-vm'
oldhostname=$(</etc/hostname)
sudo -E curlhostname $newhostname >/dev/null 2>&1
sudo -E curlsed -i "s/$oldhostname/$newhostname/g" /etc/hosts >/dev/null 2>&1
echo ccf-vm |sudo -E curltee /etc/hostname >/dev/null 2>&1
sudo -E curlsystemctl restart systemd-logind.service >/dev/null 2>&1

# Install dependancies: 
sudo -E curlsed -i 's/deb cdrom/#deb cdrom/g' /etc/apt/sources.list
sudo -E curlapt update -y
sudo -E curlapt dist-upgrade -y
sudo -E curlapt install -y vim openssh-server curl software-properties-common unzip htop

sudo -E curladd-apt-repository ppa:gift/stable -y
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo -E curlapt-key add -
sudo -E curladd-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" -y

sudo -E curlapt update -y
sudo -E curlapt dist-upgrade -y
sudo -E curlapt install -y python-software-properties python-plaso plaso-tools
sudo -E curlapt autoremove -y

# Install Mono
sudo -E curlapt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF
echo "deb http://download.mono-project.com/repo/ubuntu stable-xenial main" | sudo -E curltee /etc/apt/sources.list.d/mono-official-stable.list
sudo -E curlapt update -y
sudo -E curlapt dist-upgrade -y
sudo -E curlapt install mono-devel -y

#Install and Configure Elasticsearch
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo -E curlapt-key add -
sudo -E curlapt install apt-transport-https -y
echo "deb https://artifacts.elastic.co/packages/6.x/apt stable main" | sudo -E curltee -a /etc/apt/sources.list.d/elastic-6.x.list
sudo -E curladd-apt-repository ppa:webupd8team/java -y
sudo -E curlapt update -y
sudo -E curlapt dist-upgrade -y
echo debconf shared/accepted-oracle-license-v1-1 select true | sudo -E curldebconf-set-selections
echo debconf shared/accepted-oracle-license-v1-1 seen true | sudo -E curldebconf-set-selections
sudo -E curlapt install elasticsearch oracle-java8-installer -y

sudo -E curlsed -i 's/#network.host\: 192.168.0.1/network.host\: localhost/g' /etc/elasticsearch/elasticsearch.yml
sudo -E curlsystemctl daemon-reload
sudo -E curlsystemctl restart elasticsearch
sudo -E curlsystemctl enable elasticsearch

# Install Redis
sudo -E curladd-apt-repository ppa:chris-lea/redis-server -y
sudo -E curlapt update -y
sudo -E curlapt dist-upgrade -y
sudo -E curlapt install redis-server -y
sudo -E curlsystemctl daemon-reload
sudo -E curlsystemctl restart redis-server
sudo -E curlsystemctl enable redis-server

# Install and Configure Neo4j
neo4juser='neo4j'
neo4jpassword=$(openssl rand -base64 32)
wget -O - https://debian.neo4j.org/neotechnology.gpg.key | sudo -E curlapt-key add -
echo 'deb http://debian.neo4j.org/repo stable/' | sudo -E curltee -a /etc/apt/sources.list.d/neo4j.list
sudo -E curlapt update -y
sudo -E curlapt dist-upgrade -y
sudo -E curlapt install neo4j -y
sudo -E curl/usr/bin/neo4j-admin set-initial-password $neo4jpassword
sudo -E curlchown -R neo4j:neo4j /var/lib/neo4j/
sudo -E curlsystemctl daemon-reload
sudo -E curlsystemctl restart neo4j
sudo -E curlsystemctl enable neo4j


# Install and Configure Kibana and Logstash
sudo -E curlapt install kibana logstash -y
sudo -E curlsed -i 's@#server.host\: \"localhost\"@server.host\: \"0.0.0.0\"@g' /etc/kibana/kibana.yml
sudo -E curlsystemctl daemon-reload
sudo -E curlsystemctl restart kibana logstash
sudo -E curlsystemctl enable kibana logstash

# Configure Celery
celery_service="W1VuaXRdCkRlc2NyaXB0aW9uPUNlbGVyeSBTZXJ2aWNlCkFmdGVyPW5ldHdvcmsudGFyZ2V0CgpbU2VydmljZV0KVHlwZT1mb3JraW5nClVzZXI9Y2VsZXJ5Ckdyb3VwPWNlbGVyeQpQSURGaWxlPS9vcHQvY2VsZXJ5L2NlbGVyeS5waWRsb2NrCgpFeGVjU3RhcnQ9L3Vzci9sb2NhbC9iaW4vY2VsZXJ5IG11bHRpIHN0YXJ0IHNpbmdsZS13b3JrZXIgLUEgdGltZXNrZXRjaC5saWIudGFza3Mgd29ya2VyIC0tbG9nbGV2ZWw9aW5mbyAtLWxvZ2ZpbGU9L3Zhci9sb2cvY2VsZXJ5X3dvcmtlciAtLXBpZGZpbGU9L29wdC9jZWxlcnkvY2VsZXJ5LnBpZGxvY2sKRXhlY1N0b3A9L3Vzci9sb2NhbC9iaW4vY2VsZXJ5IG11bHRpIHN0b3B3YWl0IHNpbmdsZS13b3JrZXIgLS1waWRmaWxlPS9vcHQvY2VsZXJ5L2NlbGVyeS5waWRsb2NrIC0tbG9nZmlsZT0vdmFyL2xvZy9jZWxlcnlfd29ya2VyCkV4ZWNSZWxvYWQ9L3Vzci9sb2NhbC9iaW4vY2VsZXJ5IG11bHRpIHJlc3RhcnQgc2luZ2xlLXdvcmtlciAtLXBpZGZpbGU9L29wdC9jZWxlcnkvY2VsZXJ5LnBpZGxvY2sgLS1sb2dmaWxlPS92YXIvbG9nL2NlbGVyeV93b3JrZXIKCgpbSW5zdGFsbF0KV2FudGVkQnk9bXVsdGktdXNlci50YXJnZXQK"
sudo -E curluseradd -r -s /bin/false celery
sudo -E curlmkdir /opt/celery
sudo -E curltouch /var/log/celery_worker
sudo -E curltouch /opt/celery/celery.pidlock
sudo -E curlchown -R celery:celery /opt/celery
sudo -E curlchown -R celery:celery /opt/celery/celery.pidlock

sudo -E curlchown -R celery:celery /var/log/celery_worker
echo $celery_service |base64 -d | sudo -E curltee /etc/systemd/system/celery.service
sudo -E curlchmod g+w /etc/systemd/system/celery.service
sudo -E curlsystemctl daemon-reload
sudo -E curlsystemctl restart celery
sudo -E curlsystemctl enable celery

# Install and Configure TimeSketch
SECRET_KEY=$(openssl rand -base64 32 | sha256sum)
psql_pw=$(openssl rand -base64 32 | sha256sum)

sudo -E curlmkdir -p /etc/elasticsearch/scripts
sudo -E curlwget -O /etc/elasticsearch/scripts/add_label.groovy https://raw.githubusercontent.com/google/timesketch/master/contrib/add_label.groovy
sudo -E curlwget -O /etc/elasticsearch/scripts/toggle_label.groovy https://raw.githubusercontent.com/google/timesketch/master/contrib/toggle_label.groovy
sudo -E curlapt install postgresql -y
sudo -E curlapt install python-psycopg2 -y

echo "local all timesketch md5"|sudo -E curltee -a /etc/postgresql/9.5/main/pg_hba.conf
sudo -E curlsystemctl restart postgresql.service
echo "create user timesketch with password '$psql_pw';" | sudo -E curl-u postgres psql || true
echo "create database timesketch owner timesketch;" | sudo -E curl-u postgres psql || true

sudo -E curlapt install python-pip python-dev libffi-dev -y
sudo -E curl-H pip install --upgrade pip
sudo -E curl-H pip install timesketch

sudo -E curlcp /usr/local/share/timesketch/timesketch.conf /etc/
sudo -E curlsed -i "s@SECRET_KEY = u''@SECRET_KEY = u'$SECRET_KEY'@g" /etc/timesketch.conf
sudo -E curlsed -i "s@<USERNAME>\:<PASSWORD>@timesketch\:$psql_pw@g" /etc/timesketch.conf
sudo -E curlsed -i "s/UPLOAD_ENABLED = False/UPLOAD_ENABLED = True/g" /etc/timesketch.conf
sudo -E curlsed -i "s/GRAPH_BACKEND_ENABLED = False/GRAPH_BACKEND_ENABLED = True/g" /etc/timesketch.conf
sudo -E curlsed -i "s@NEO4J_USERNAME = u''@NEO4J_USERNAME = u'$neo4juser'@g" /etc/timesketch.conf
sudo -E curlsed -i "s@NEO4J_PASSWORD = u''@NEO4J_PASSWORD = u'$neo4jpassword'@g" /etc/timesketch.conf
sudo -E curlsed -i "s/GRAPH_BACKEND_ENABLED = False/GRAPH_BACKEND_ENABLED = True/g" /etc/timesketch.conf


timesketchpassword=$(openssl rand -base64 32)
tsctl add_user -u cdqr -p "$timesketchpassword"

timesketch_service="W1VuaXRdCkRlc2NyaXB0aW9uPVRpbWVTa2V0Y2ggU2VydmljZQpBZnRlcj1uZXR3b3JrLnRhcmdldAoKW1NlcnZpY2VdClVzZXI9dGltZXNrZXRjaApHcm91cD10aW1lc2tldGNoCkV4ZWNTdGFydD0vdXNyL2xvY2FsL2Jpbi90c2N0bCBydW5zZXJ2ZXIgLWggMC4wLjAuMCAtcCA1MDAwIC0tdGhyZWFkZWQgLS1wYXNzdGhyb3VnaC1lcnJvcnMgCgpbSW5zdGFsbF0KV2FudGVkQnk9bXVsdGktdXNlci50YXJnZXQK"

sudo -E curluseradd -r -s /bin/false timesketch

echo $timesketch_service |base64 -d | sudo -E curltee /etc/systemd/system/timesketch.service
sudo -E curlchmod g+w /etc/systemd/system/timesketch.service
sudo -E curlsystemctl daemon-reload
sudo -E curlsystemctl restart timesketch.service
sudo -E curlsystemctl enable timesketch.service

# Install and Configure Cerebro
cerebro_service="W1VuaXRdCkRlc2NyaXB0aW9uPUNlcmVicm8gU2VydmljZQpBZnRlcj1uZXR3b3JrLnRhcmdldAoKW1NlcnZpY2VdClVzZXI9Y2VyZWJybwpHcm91cD1jZXJlYnJvCkV4ZWNTdGFydD0vb3B0L2NlcmVicm8vY2VyZWJyby0wLjcuMi9iaW4vY2VyZWJybwoKW0luc3RhbGxdCldhbnRlZEJ5PW11bHRpLXVzZXIudGFyZ2V0Cg=="
cerebro_secret=$(openssl rand -base64 32 | sha256sum)
sudo -E curluseradd -r -s /bin/false cerebro
sudo -E curlmkdir /opt/cerebro

cerebro_version="0.7.2"
sudo -E curlwget -O "/opt/cerebro/cerebro-$cerebro_version.tgz" "https://github.com/lmenezes/cerebro/releases/download/v$cerebro_version/cerebro-$cerebro_version.tgz"
sudo -E curltar xzf "/opt/cerebro/cerebro-$cerebro_version.tgz" -C "/opt/cerebro/"
sudo -E curlrm -rf "/opt/cerebro/cerebro-$cerebro_version.tgz"
sudo -E curlchown -R cerebro:cerebro /opt/cerebro
sudo -E curlchmod +w /opt/cerebro
sudo -E curlsed -i "s@./cerebro.db@/opt/cerebro/cerebro-$cerebro_version/cerebro.db@g" "/opt/cerebro/cerebro-$cerebro_version/conf/application.conf"
sudo -E curlsed -i "s/secret = .*/secret = \"$cerebro_secret\"/g"  "/opt/cerebro/cerebro-$cerebro_version/conf/application.conf"
sudo -E curlsed -i "s@hosts = \[@hosts = \[\\n\  {\\n    host = \"http\://localhost\:9200\"\\n    name = \"CCF-VM\"\\n  \}@g" "/opt/cerebro/cerebro-$cerebro_version/conf/application.conf"
#sudo -E curlsed -i "s@basePath = \"/\"@basePath = \"/opt/cerebro/cerebro-$cerebro_version\"@g" "/opt/cerebro/cerebro-$cerebro_version/conf/application.conf"

cerebro_config="aG9zdHMgPSBbCiAgewogICAgaG9zdCA9ICJodHRwOi8vbG9jYWxob3N0OjkyMDAiCiAgICBuYW1lID0gIkNDRi1WTSIKICB9Cg=="
echo $cerebro_service |base64 -d | sudo -E curltee /etc/systemd/system/cerebro.service
sudo -E curlchmod g+w /etc/systemd/system/cerebro.service
sudo -E curlsystemctl daemon-reload
sudo -E curlsystemctl restart cerebro.service
sudo -E curlsystemctl enable cerebro.service

# Installs and Configures CDQR and CyLR
curl -sSL https://raw.githubusercontent.com/rough007/CCF-VM/master/scripts/update.sh |bash

echo ""
echo ""
echo "System Health Checks"
# system health checks
declare -a services=('elasticsearch' 'postgresql' 'celery' 'neo4j' 'redis' 'logstash' 'kibana' 'timesketch')
# Ensure all Services are started
for item in "${services[@]}"
do
    echo "  Bringing up $item"
    sudo -E curlsystemctl restart $item
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

echo ""
echo ""
echo "TimeSketch Initial User Information (reset with 'tsctl add_user -u cdqr -p <password>')"
echo "Username: cdqr"
echo "Password: $timesketchpassword"
exec bash

