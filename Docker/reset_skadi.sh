#/bin/bash
set -e

# Set the value for if it should display banner with pause or not
banner=${BANNER:-true}

hello_message () {
  echo "Completely resetting Skadi and removing all saved data"
  read -n 1 -r -s -p "Press any key to continue... or CTRL+C to exit (nothing has been deleted yet)"
  echo ""
}

reset_docker () {
  set -x
  docker-compose down
  docker volume prune --force
  docker system prune --force
}


############ MAIN PROGRAM #############
if [ $banner = "true" ]
  then
    hello_message
fi
reset_docker
