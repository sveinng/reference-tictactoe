#!/bin/bash
#
# Bootstrap AWS Ubuntu server for running Docker instance
#

# Basic update / upgrade + linux extra
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install linux-image-extra-$(uname -r) linux-image-extra-virtual -y

# Add support for Docker repository
sudo apt-get install apt-transport-https ca-certificates
sudo apt-key adv \
               --keyserver hkp://ha.pool.sks-keyservers.net:80 \
               --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
echo "deb https://apt.dockerproject.org/repo ubuntu-xenial main" |  sudo tee /etc/apt/sources.list.d/docker.list

# Install latest docker and start docker service
sudo apt-get update
sudo apt-get install docker-engine -y
sudo service docker start

# Install latest docker compose and make executable
sudo curl -L "https://github.com/docker/compose/releases/download/1.9.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Add ubuntu user to Docker group
sudo usermod -a -G docker ubuntu

# Fetch latest docker-compose.yaml and start dockers
curl -sS https://github.com/sveinng/reference-tictactoe/blob/master/docker-compose-env.yaml
curl -sS https://github.com/sveinng/reference-tictactoe/blob/master/run-compose.sh
bash run-compose.sh
