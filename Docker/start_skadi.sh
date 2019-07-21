#/bin/bash
set -e

# Set the value for if it should display banner with pause or not
banner=${BANNER:-true}

hello_message () {
  echo "Starting a secure dockerized container setup of Skadi"
  echo "Please ensure you have at least 8 GB RAM and 4 cores allocated to docker"
  echo "Ports 80, 5432, 9200 must be available. If not, it will not work correctly"
  read -n 1 -r -s -p "If this is configured press any key to continue... or CTRL+C to exit (nothing has been installed)"
  echo ""
}

os_setup () {
  if [ $(uname -s) = "Linux" ]
    then
      echo ""
      echo "Detected Linux operating system"
      echo "Setting the vm.max_map_count kernel to 262144 for elasticsearch to start"
      echo "WARNING!!! This requires sudo to make this change."
      sudo sysctl -w vm.max_map_count=262144
      echo vm.max_map_count=262144 | sudo tee -a /etc/sysctl.conf
      echo ""
  fi
}

start_docker () {
  chmod +x grafana/grafana/setup.sh
  docker-compose up -d
}

function Set_PsEnv () {
  set -a # automatically export all variables
  source .env
  set +a
}

configure_elastic_kibana () {
  NGINX_USER="${GRAFANA_USER:-skadi}"
  NGINX_PASSWORD="${GRAFANA_PASSWORD:-skadi}"
  echo ""
  echo "Setting up ElasticSearch and Kibana"
  echo ""
  # Create a template in ES that sets the number of replicas for all indexes to 0
  echo "Waiting for ElasticSearch service to respond to requests"
  until $(curl --output /dev/null --silent --head --fail http://localhost:9200); do
      printf '.'
      sleep 5
  done
  echo "Setting the ElasticSearch default number of replicas to 0"

  curl -XPUT 'localhost:9200/_template/number_of_replicas' \
      -d '{"template": "*","settings": {"number_of_replicas": 0}}' \
      -H'Content-Type: application/json'  > /dev/null 2>&1

  echo "Waiting for Kibana service to respond to requests"
  until $(curl --output /dev/null -u $NGINX_USER:$NGINX_PASSWORD --silent --head --fail http://localhost/kibana); do
      printf '.'
      sleep 5
  done

  echo "Importing Saved Objects to Kibana and setting default index"
  curl -X POST "http://localhost/kibana/api/saved_objects/_bulk_create" -u $NGINX_USER:$NGINX_PASSWORD -H 'kbn-xsrf: true' -H 'Content-Type: application/json' --data-binary @../objects/kibana_6.x_cli_import.json  > /dev/null 2>&1
  curl -X POST "http://localhost/kibana/api/kibana/settings/defaultIndex" -u $NGINX_USER:$NGINX_PASSWORD -H "Content-Type: application/json" -H "kbn-xsrf: true" -d '{"value": "06876cd0-dfc5-11e8-bc06-31e345541948"}'  > /dev/null 2>&1
}

############ MAIN PROGRAM #############
if [ $banner = "true" ]
  then
    hello_message
fi
os_setup
start_docker
Set_PsEnv
configure_elastic_kibana
