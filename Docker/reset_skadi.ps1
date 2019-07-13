#! /usr/bin/pwsh
$ErrorActionPreference = "Stop"

# Set the value for if it should display banner with pause or not
$banner=${BANNER:-true}

function hello_message {
  echo "Completely resetting Skadi and removing all saved data"
  echo "If you already have this configured press any key to continue... or CTRL+C to exit (nothing has been installed)"
  $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
  echo ""
}

function reset_docker () {
  docker-compose -f .\docker-compose-windows.yml down
  docker volume prune --force
  docker system prune --force
}


############ MAIN PROGRAM #############
if ( $banner = "true" ) {
  hello_message
}

reset_docker
