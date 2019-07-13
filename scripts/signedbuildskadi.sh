#!/bin/bash
set -e

# Set the value for if it should display banner with pause or not
banner=${BANNER:-true}

# Choosing to use default passwords or not
default_skadi_passwords=${DEFAULT_PASSWORDS:-false}

# Set the installation branch
install_branch=${INSTALL_BRANCH:-"just_docker"}

# Set the value for if the hostname should be changed
hostname_change=${SKADI_HOSTNAME:-true}

# Set the value for if the skadi user should be created
create_skadi_user=${MAKE_SKADI_USER:-true}

# Set the value for if the server time should be set to UTC
set_time_utc=${UTC_TIME:-true}

# Default Values
SKADI_USER="skadi"
SKADI_PASS="skadi"
SKADI_USER_HOME="/home/$SKADI_USER"
TIMESKETCH_USER="skadi"
TIMESKETCH_PASSWORD="skadi"
NGINX_USER="skadi"
NGINX_PASSWORD="skadi"
GRAFANA_USER=$NGINX_USER
GRAFANA_PASSWORD=$NGINX_PASSWORD

hello_message () {
  echo "Welcome to installing a secure dockerized container setup of Skadi"
  echo "Please ensure you have at least 8 GB RAM and 4 cores allocated to the host"
  read -n 1 -r -s -p "If you already have this configured press any key to continue... or CTRL+C to exit (nothing has been installed)"
  echo ""
}

setup_host () {
  echo ""
  echo "Setting up host"
  echo ""
  # Update
  sudo apt-get update && sudo apt-get dist-upgrade -y

  # Install deps
  sudo apt-get install -y \
    openssh-server \
    git \
    curl \
    glances \
    unzip \
    vim \
    htop \
    screen \
    gnupg \
    net-tools \
    software-properties-common \
    apache2-utils

  # Clean APT
    sudo apt-get -y autoremove --purge
    sudo apt-get -y clean
    sudo apt-get -y autoclean

  # Set the vm.max_map_count kernel setting needs to be set to at least 262144 for production use
    sudo sysctl -w vm.max_map_count=262144
    echo vm.max_map_count=262144 | sudo tee -a /etc/sysctl.conf

  # Set Hostname to skadi by default with option to not to
    if [ $hostname_change = "true" ]
      then
      echo "Renaming Host to skadi"
      newhostname='skadi'
      oldhostname=$(</etc/hostname)
      sudo hostname $newhostname >/dev/null 2>&1
      sudo sed -i "s/$oldhostname/$newhostname/g" /etc/hosts >/dev/null 2>&1
      echo skadi |sudo tee /etc/hostname >/dev/null 2>&1
      sudo systemctl restart systemd-logind.service >/dev/null 2>&1
    else
      echo "Not renaming host"
    fi

    # Set Server to UTC or not
    if [ $set_time_utc = "true" ]
      then
      # Set Timezone to UTC
      sudo timedatectl set-timezone UTC
    fi

  # Create Skadi user by default with option to not to
  if [ $create_skadi_user = "true" ]
    then
    if ! id -u $SKADI_USER >/dev/null 2>&1; then
        echo "==> Creating $SKADI_USER user"
        echo "" >> /opt/skadi_credentials
        echo "  Created OS Account:" >> /opt/skadi_credentials
        echo "     - Username: $SKADI_USER" >> /opt/skadi_credentials
        echo "     - Password: $SKADI_PASS" >> /opt/skadi_credentials
        /usr/sbin/groupadd $SKADI_USER
        /usr/sbin/useradd $SKADI_USER -g $SKADI_USER -G sudo -d $SKADI_USER_HOME --create-home -s "/bin/bash"
        echo "$SKADI_USER:$SKADI_PASS" | chpasswd

        # Set up sudo
        echo "==> Giving $SKADI_USER sudo powers"
        echo "$SKADI_USER        ALL=(ALL)       NOPASSWD: ALL" > /etc/sudoers.d/$SKADI_USER
        chmod 440 /etc/sudoers.d/$SKADI_USER
    fi
  else
    echo "Not creating skadi user"
    SKADI_USER=$(whoami)
  fi

  # Enable and Configure UFW Firewall
  echo "Enabling UFW firewall to only allow OpenSSH and Ngninx Full"
  sudo ufw allow 80
  sudo ufw allow 443
  sudo ufw allow 'OpenSSH'
  sudo ufw --force enable
}

change_credentials () {
  echo ""
  echo "Using random credentials"
  echo ""
  # Set Credentials
  SECRET_KEY=$(openssl rand -hex 32)
  POSTGRES_USER="timesketch"
  psql_pw=$(openssl rand -hex 32)
  neo4juser='neo4j'

  echo "Using random username and passwords for OS Account, TimeSketch, Nginx proxy / Grafana"
  echo "Writing all credentials to /opt/skadi_credentials"
  TIMESKETCH_USER="skadi_$(openssl rand -hex 3)"
  TIMESKETCH_PASSWORD=$(openssl rand -hex 32)
  NGINX_USER="skadi_$(openssl rand -hex 3)"
  NGINX_PASSWORD=$(openssl rand -hex 32)
  GRAFANA_USER=$NGINX_USER
  GRAFANA_PASSWORD=$NGINX_PASSWORD
  SKADI_PASS=$(openssl rand -hex 32)
  SKADI_USER_HOME="/home/$SKADI_USER"
  echo "  Proxy & Grafana Account:" > /opt/skadi_credentials
  echo "     - Username: $NGINX_USER" >> /opt/skadi_credentials
  echo "     - Password: $NGINX_PASSWORD" >> /opt/skadi_credentials
  echo "" >> /opt/skadi_credentials
  echo "  TimeSketch Account:" >> /opt/skadi_credentials
  echo "     - Username: $TIMESKETCH_USER" >> /opt/skadi_credentials
  echo "     - Password: $TIMESKETCH_PASSWORD" >> /opt/skadi_credentials
}

setup_docker () {
  echo ""
  echo "Setting up docker"
  echo ""
  # Add Docker gpg key
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
  sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

  # Install Docker
  sudo apt-get update
  sudo apt-get install docker-ce -y
  sudo systemctl enable docker

  # Install Docker-Compose
  sudo curl -L "https://github.com/docker/compose/releases/download/1.23.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  sudo chmod +x /usr/local/bin/docker-compose
  sudo curl -L https://raw.githubusercontent.com/docker/compose/1.23.1/contrib/completion/bash/docker-compose -o /etc/bash_completion.d/docker-compose

  # Add skadi to docker usergroup
  sudo usermod -aG docker $SKADI_USER
}

download_skadi () {
  echo ""
  echo "Downloading Skadi"
  echo ""
  sudo git clone --branch $install_branch https://github.com/orlikoski/Skadi.git /opt/Skadi

  # Update permissions on Skadi directory
  sudo chown -R $SKADI_USER:$SKADI_USER /opt/Skadi
}

cdqr_cylr_config () {
  echo ""
  echo "Setting up CDQR and CyLR"
  echo ""
  # Copy cdqr script to /usr/local/bin
  sudo cp /opt/Skadi/scripts/cdqr /usr/local/bin/cdqr
  sudo chmod +x /usr/local/bin/cdqr

  # Installs and Configures CDQR and CyLR
  sudo -E bash /opt/Skadi/scripts/update.sh
}

timesketch_configs () {
  echo ""
  echo "Setting up Timesketch configs with custom credentials"
  echo ""
  cp /opt/Skadi/Docker/timesketch/timesketch_default.conf /opt/Skadi/Docker/timesketch/timesketch_default.conf.bak
  # Write TS and Postgres creds to .env file
  sudo sed -i -E "s@TIMESKETCH_USER=.*@TIMESKETCH_USER='$TIMESKETCH_USER'@g" /opt/Skadi/Docker/.env
  sudo sed -i -E "s@TIMESKETCH_PASSWORD=.*@TIMESKETCH_PASSWORD='$TIMESKETCH_PASSWORD'@g" /opt/Skadi/Docker/.env
  sudo sed -i -E "s@POSTGRES_USER=.*@POSTGRES_USER='$POSTGRES_USER'@g" /opt/Skadi/Docker/.env
  sudo sed -i -E "s@POSTGRES_PASSWORD=.*@POSTGRES_PASSWORD='$psql_pw'@g" /opt/Skadi/Docker/.env

 # Write TimeSketch config file on host
  sudo sed -i "s@timesketch\:d2aea7c843bf6cc049a8199ffaa5d468108878819210990f7f33c424882b52ba@$POSTGRES_USER\:$psql_pw@g" /opt/Skadi/Docker/timesketch/timesketch_default.conf
  sudo sed -i "s@'b75b9987200f2f1b15c4dbf800214fbc420bf4a0f3f3895dcc40eb5e9ca185c2-'@'$SECRET_KEY'@g" /opt/Skadi/Docker/timesketch/timesketch_default.conf
}

proxy_grafana_auth ()  {
  echo ""
  echo "Setting up Proxy and Grafana auth with custom credentials"
  echo ""
  # Setup Grafana Auth
  sudo sed -i -E "s@GRAFANA_USER=.*@GRAFANA_USER='$GRAFANA_USER'@g" /opt/Skadi/Docker/.env
  sudo sed -i -E "s@GRAFANA_PASSWORD=.*@GRAFANA_PASSWORD='$GRAFANA_PASSWORD'@g" /opt/Skadi/Docker/.env

  # Setup Nginx Auth
  sudo rm /opt/Skadi/Docker/nginx/auth/.skadi_auth
  echo $NGINX_PASSWORD | sudo htpasswd -i -c /opt/Skadi/Docker/nginx/auth/.skadi_auth $NGINX_USER
}

start_docker () {
  echo ""
  echo "Bringing up Skadi"
  echo ""
  cd /opt/Skadi/Docker
  sudo BANNER=false bash ./start_skadi.sh
}

configure_elastic_kibana () {
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
      -H'Content-Type: application/json'

  echo "Waiting for Kibana service to respond to requests"
  until $(curl --output /dev/null -u $NGINX_USER:$NGINX_PASSWORD --silent --head --fail http://localhost/kibana); do
      printf '.'
      sleep 5
  done

  echo "Importing Saved Objects to Kibana and setting default index"
  curl -X POST "http://localhost/kibana/api/saved_objects/_bulk_create" -u $NGINX_USER:$NGINX_PASSWORD -H 'kbn-xsrf: true' -H 'Content-Type: application/json' --data-binary @/opt/Skadi/objects/kibana_6.x_cli_import.json
  curl -X POST "http://localhost/kibana/api/kibana/settings/defaultIndex" -u $NGINX_USER:$NGINX_PASSWORD -H "Content-Type: application/json" -H "kbn-xsrf: true" -d '{"value": "06876cd0-dfc5-11e8-bc06-31e345541948"}'
}

ensure_TS_up () {
# The TimeSketch container needs to be running before continuing and this
# requires the other containers to be up and running too. This can take time
# so this loop ensures all the parts are running and timesketch is responding
# to web requests before continuing
echo ""
echo ""
echo "Ensuring Timesketch is running correctly"
echo "Press CTRL-C at any time to stop installation"
until $(curl --output /dev/null -u $NGINX_USER:$NGINX_PASSWORD --silent --head --fail http://localhost/timesketch); do
    echo "No response, restarting the TimeSketch container and waiting 10 seconds to try again"
    sudo docker restart timesketch
    sleep 10
done
echo "TimeSketch available. Continuing"
}

goodbye_message () {
echo ""
echo ""
echo ""
echo "Skadi Setup is Complete"
echo ""
echo "The Nginx reverse proxy setup and can be accessed at http://<IP Address> or http://localhost if installed locally:"
if [ $default_skadi_passwords = "false" ]
  then
    echo "The following are the credentials needed to access this build and are stored in /opt/skadi_credentials if run-time generated credentials was chosen: "
    echo ""
    cat /opt/skadi_credentials
    echo ""
fi
echo ""
echo "The following files have credentials used in the build process stored in them:"
echo "  - /opt/skadi_credentials (only if run-time generated credentials chosen)"
echo "  - /opt/Skadi/Docker/.env"
echo "  - /opt/Skadi/Docker/skadi_dockprom/.env"
}

############ MAIN PROGRAM #############
if [ $banner = "true" ]
  then
    hello_message
fi
setup_host
download_skadi
setup_docker
if [ $default_skadi_passwords = "false" ]
  then
    change_credentials
    timesketch_configs
    proxy_grafana_auth
else
    echo "Using Skadi default username and password of skadi:skadi for OS Account, TimeSketch, Nginx proxy, and Grafana"
fi
cdqr_cylr_config
start_docker
configure_elastic_kibana
ensure_TS_up
goodbye_message
