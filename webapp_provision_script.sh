#!/bin/bash

sudo dnf update -y
sudo dnf install git -y
sudo dnf install docker -y

sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker ec2-user
newgrp docker

sudo curl -L "https://github.com/docker/compose/releases/download/v2.10.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose


mkdir /home/ec2-user/repo
cd /home/ec2-user/repo

git clone https://github.com/djoksa4/very-simple-webapp.git
docker-compose -f /home/ec2-user/repo/very-simple-webapp/docker-compose.yml up -d