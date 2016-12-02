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

# Create run scripts
echo "*** Creating run scripts"

cat <<EOF > ~ubuntu/prod.tag
be2eec827d38d837a7dbdc13327c0cd32e89a206
EOF

cat <<EOF > /etc/profile.d/docker_prod_tag.sh
export PROD_TAG=$(cat ~ubuntu/prod.tag)
EOF

cat <<'EOF' > ~ubuntu/docker-compose.yaml
version: '2'
services:
  server:
    container_name: ttt-server
    environment:
      - 'PORT=80'
      - 'NODE_ENV=production'
      - 'DATABASE_PROD_USER=postgres'
      - 'DATABASE_PROD_PASS=CVakcK22D4pntv7Y'
      - 'DATABASE_PROD_HOST=pg-prod'
    image: 'sveinn/tictactoe:$PROD_TAG'
    build:
      context: '.'
      dockerfile: 'Dockerfile'
    ports:
      - '8080:8080'
    links:
      - 'pg-prod'
    depends_on:
      - "pg-prod"
  pg-prod:
    container_name: ttt-database
    environment:
      - 'POSTGRES_PASSWORD=CVakcK22D4pntv7Y'
    image: postgres
EOF

cat <<'EOF' > ~ubuntu/run-compose.sh
#!/bin/bash
# Compose image from production git revision and start dockers

export PROD_TAG=$(cat ~ubuntu/prod.tag)
docker-compose -f ~ubuntu/docker-compose.yaml pull
docker-compose -f ~ubuntu/docker-compose.yaml up
EOF

cat <<'EOF' > ~ubuntu/stop-compose.sh
#!/bin/bash
# Stop composed dockers

export PROD_TAG=$(cat ~ubuntu/prod.tag)
docker-compose -f ~ubuntu/docker-compose.yaml stop
EOF

cat <<'EOF' > /etc/systemd/system/docker-ttt.service
[Unit]
Description=TicTacToe service
Requires=docker.service
After=docker.service

[Service]
Restart=always
ExecStart=/home/ubuntu/run-compose.sh
ExecStop=/home/ubuntu/stop-compose.sh

[Install]
WantedBy=default.target
EOF

echo "*** Fixing ownership and permissions"
chown ubuntu:ubuntu ~ubuntu/docker-compose.yaml ~ubuntu/run-compose.sh ~ubuntu/stop-compose.sh ~ubuntu/prod.tag
chmod +x ~ubuntu/run-compose.sh ~ubuntu/stop-compose.sh 

echo "*** Configuring systemd to control docker"
systemctl enable docker-ttt.service

echo "*** All done - lets reboot and get to business!"
reboot
