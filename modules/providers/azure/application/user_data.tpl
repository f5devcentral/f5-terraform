#!/bin/bash

### Xenial 16.04
# Install Docker
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"


sudo apt-get update
sudo apt-get install -y docker-ce

# Deploy App 
sudo docker run --name my_app -p 80:80 -d ${docker_image}