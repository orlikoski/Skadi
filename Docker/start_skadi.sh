#/bin/bash
set -e

hello_message () {
  echo "Starting a secure dockerized container setup of Skadi"
  echo "Please ensure you have at least 8 GB RAM and 4 cores allocated to the host"
  read -n 1 -r -s -p "If you already have this configured press any key to continue... or CTRL+C to exit (nothing has been installed)"
  echo ""
}

start_docker () {
  cd ./skadi_dockprom
  docker-compose up -d
  cd ..
  docker-compose up -d
}


############ MAIN PROGRAM #############
hello_message
start_docker
