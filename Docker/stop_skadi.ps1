#! /usr/bin/pwsh
$ErrorActionPreference = "Stop"

# Set the value for if it should display banner with pause or not
$banner=$env:BANNER

function hello_message {
  echo "Stopping  Skadi"
    echo "If you want to stop the container, and preserve the data, press any key to continue... or CTRL+C to exit"
  $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
  echo ""
}

function stop_docker {
  docker-compose -f .\docker-compose-windows.yml stop
}


############ MAIN PROGRAM #############
if ( $banner -ne "false" ) {
  hello_message
}

stop_docker
