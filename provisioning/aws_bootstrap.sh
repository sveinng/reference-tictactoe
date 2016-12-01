#!/bin/bash
#
# Bootstrap AWS Ubuntu server for running Docker instance
#

# Basic update / upgrade + linux extra
apt-get update
apt-get upgrade -y
apt-get install linux-image-extra-$(uname -r) linux-image-extra-virtual -y

# Add support for Docker repository
apt-get install apt-transport-https ca-certificates
apt-key adv \
               --keyserver hkp://ha.pool.sks-keyservers.net:80 \
               --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
echo "deb https://apt.dockerproject.org/repo ubuntu-xenial main" |  sudo tee /etc/apt/sources.list.d/docker.list

# Install latest docker and start docker service
apt-get update
apt-get install docker-engine -y
service docker start

# Install latest docker compose and make executable
curl -L "https://github.com/docker/compose/releases/download/1.9.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Add ubuntu user to Docker group
usermod -a -G docker ubuntu

# Fetch latest docker-compose.yaml and start dockers
echo "*** Fetching docker-composer scripts"
cd /home/ubuntu/
wget https://raw.githubusercontent.com/sveinng/reference-tictactoe/master/docker-compose-env.yaml
wget https://raw.githubusercontent.com/sveinng/reference-tictactoe/master/run-compose.sh

echo "*** Fixing ownership and permissions"
chown ubuntu docker-compose-env.yaml run-compose.sh
chmod +x run-compose.sh

echo "*** Executing run-compose.sh"
su - ubuntu -c /home/ubuntu/run-compose.sh
