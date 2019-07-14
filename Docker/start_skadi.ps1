#! /usr/bin/pwsh
$ErrorActionPreference = "Stop"

# Set the value for if it should display banner with pause or not
$banner=$env:BANNER

function hello_message {
  echo "Starting a secure dockerized container setup of Skadi"
  echo "Please ensure you have at least 8 GB RAM and 4 cores allocated to docker"
  echo "If you already have this configured press any key to continue... or CTRL+C to exit (nothing has been installed)"
  $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
  echo ""
}

function start_docker {
  docker-compose -f .\docker-compose-windows.yml up -d
}

function configure_elastic_kibana {
  echo ""
  echo "Setting up ElasticSearch and Kibana"
  echo ""
  # Create a template in ES that sets the number of replicas for all indexes to 0
  echo "Waiting for ElasticSearch service to respond to requests"
  $ErrorActionPreference = "SilentlyContinue"
  do {

    $KB_test_Params = @{
        URI = 'http://localhost:9200'
    }
    $response = Invoke-WebRequest @KB_test_Params
    Start-Sleep -s 5
  } until ( $response.StatusCode -eq [System.Net.HttpStatusCode]::OK )
  $ErrorActionPreference = "Stop"

  echo "Setting the ElasticSearch default number of replicas to 0"
  $ES_Params = @{
      Body = '{"template": "*","settings": {"number_of_replicas": 0}}'
      Method = 'POST'
      URI = 'http://localhost:9200/_template/number_of_replicas'
      Headers = @{'content-type'='application/json'}
  }

  Invoke-RestMethod @ES_Params 2>&1>$null

  echo "Waiting for Kibana service to respond to requests"
  $username = "$env:GRAFANA_USER"
  $password = "$env:GRAFANA_PASSWORD"
  $ErrorActionPreference = "SilentlyContinue"
  do {

    $KB_test_Params = @{
        URI = 'http://localhost/kibana/app/kibana#/home?_g=()'
        Headers = @{'Authorization'='Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$($username):$($password)"))}
    }
    $response = Invoke-WebRequest @KB_test_Params
    Start-Sleep -s 5
  } until ( $response.StatusCode -eq [System.Net.HttpStatusCode]::OK )
  $ErrorActionPreference = "Stop"

  echo "Importing Saved Objects to Kibana and setting default index"
  $KB1_Params = @{
      Method = 'POST'
      URI = 'http://localhost/kibana/api/saved_objects/_bulk_create'
      Headers = @{'Authorization'='Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$($username):$($password)"));'kbn-xsrf'='true';'content-type'='application/json'}
      InFile = "../objects/kibana_6.x_cli_import.json"
  }
  Invoke-RestMethod @KB1_Params 2>&1>$null


  $KB2_Params = @{
      Method = 'POST'
      URI = 'http://localhost/kibana/api/kibana/settings/defaultIndex'
      Headers = @{'Authorization'='Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$($username):$($password)"));'kbn-xsrf'='true';'content-type'='application/json'}
      Body = '{"value": "06876cd0-dfc5-11e8-bc06-31e345541948"}'
  }

  Invoke-RestMethod @KB2_Params 2>&1>$null
}

<#
.Source
https://gist.github.com/grenzi/82e6cb8215cc47879fdf3a8a4768ec09
.Synopsis
Exports environment variable from the .env file to the current process.

.Description
This function looks for .env file in the current directoty, if present
it loads the environment variable mentioned in the file to the current process.

based on https://github.com/rajivharris/Set-PsEnv

.Example
 Set-PsEnv

.Example
 # This is function is called by convention in PowerShell
 # Auto exports the env variable at every prompt change
 function prompt {
     Set-PsEnv
 }
#>
function Set-PsEnv {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    param($localEnvFile = ".\.env")

    #return if no env file
    if (!( Test-Path $localEnvFile)) {
        Throw "could not open $localEnvFile"
    }

    #read the local env file
    $content = Get-Content $localEnvFile -ErrorAction Stop
    Write-Verbose "Parsed .env file"

    #load the content to environment
    foreach ($line in $content) {
        if ($line.StartsWith("#")) { continue };
        if ($line.Trim()) {
            $line = $line.Replace("`"","")
            $kvp = $line -split "=",2
            if ($PSCmdlet.ShouldProcess("$($kvp[0])", "set value $($kvp[1])")) {
                [Environment]::SetEnvironmentVariable($kvp[0].Trim(), $kvp[1].Trim(), "Process") | Out-Null
            }
        }
    }
}

############ MAIN PROGRAM #############
if ( $banner -ne "false" ) {
  hello_message
}

start_docker
Set-PsEnv
configure_elastic_kibana
