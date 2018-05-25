#!/bin/bash
# This script converts Skadi 2018.1 to 2018.2
# NOTE: All of the data in the ELK stack will be lost
sudo apt purge elasticsearch kibana logstash -y
sudo rm -rf /var/lib/elasticsearch /etc/elasticsearch /var/lib/kibana
sudo -H pip install --upgrade pip
sudo -H pip2 install --upgrade pip
sudo -H pip2 uninstall elasticsearch -y

sudo rm  /etc/apt/sources.list.d/elastic-*
echo "deb https://artifacts.elastic.co/packages/5.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-5.x.list
sudo apt update && sudo apt dist-upgrade -y
sudo apt autoremove -y

sudo -H pip install --upgrade botocore
sudo -H pip install --upgrade boto3

sudo wget -O /etc/elasticsearch/scripts/add_label.groovy https://raw.githubusercontent.com/google/timesketch/master/contrib/add_label.groovy
sudo wget -O /etc/elasticsearch/scripts/toggle_label.groovy https://raw.githubusercontent.com/google/timesketch/master/contrib/toggle_label.groovy

sudo apt install elasticsearch kibana logstash -y
sudo systemctl stop elasticsearch logstash kibana cerebro timesketch
sudo sed -i 's@#server.host\: \"localhost\"@server.host\: \"0.0.0.0\"@g' /etc/kibana/kibana.yml
sudo sed -i 's/#network.host\: 192.168.0.1/network.host\: localhost/g' /etc/elasticsearch/elasticsearch.yml

sudo systemctl restart elasticsearch logstash kibana cerebro timesketch
sudo /bin/systemctl daemon-reload &&
sudo /bin/systemctl enable elasticsearch logstash kibana &&
sudo /bin/systemctl start elasticsearch logstash kibana

curl -X PUT "localhost:9200/_template/all" -H 'Content-Type: application/json' -d'
{
  "template": "*",
  "settings": {
    "number_of_replicas": 0
  }
}
'

# Configure Kibana Credentials
k_user="skadi"
k_pass="skadi"
echo $k_pass | sudo htpasswd -i -c /etc/nginx/.kibana_auth $k_user

# Configure Cerebro Credentials
c_user="skadi"
c_pass="skadi"
echo $c_pass | sudo htpasswd -i -c /etc/nginx/.cerebro_auth $c_user

sudo systemctl restart nginx
sudo systemctl enable nginx
