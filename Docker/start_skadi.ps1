#! /usr/bin/pwsh
$ErrorActionPreference = "Stop"

# Set the value for if it should display banner with pause or not
$banner=$env:BANNER

function hello_message {
  echo "Starting a secure dockerized container setup of Skadi"
  echo "Please ensure you have at least 8 GB RAM and 4 cores allocated to the host"
  echo "If you already have this configured press any key to continue... or CTRL+C to exit (nothing has been installed)"
  $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
  echo ""
}

function start_docker {
  docker-compose -f .\docker-compose-windows.yml up -d
}


############ MAIN PROGRAM #############
if ( $banner -ne "false" ) {
  hello_message
}

start_docker
