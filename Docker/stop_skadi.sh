#/bin/bash
set -e

# Set the value for if it should display banner with pause or not
banner=${BANNER:-true}

hello_message () {
  echo "Stopping Skadi"
  read -n 1 -r -s -p "If you want to stop the containers, and preserve the data, press any key to continue... or CTRL+C to exit"
  echo ""
}

stop_docker () {
  chmod +x grafana/grafana/setup.sh
  docker-compose stop
}


############ MAIN PROGRAM #############
if [ $banner = "true" ]
  then
    hello_message
fi
stop_docker
