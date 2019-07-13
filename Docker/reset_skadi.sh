#/bin/bash
set -e

hello_message () {
  echo "Completely resetting Skadi and removing all saved data"
  read -n 1 -r -s -p "Press any key to continue... or CTRL+C to exit (nothing has been deleted yet)"
  echo ""
}

reset_docker () {
  docker-compose down
  docker volume prune --force
  docker system prune --force
}


############ MAIN PROGRAM #############
hello_message
reset_docker
