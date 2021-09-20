#!/usr/bin/env bash

sudo apt-get remove docker docker-engine docker.io containerd runc

sudo apt-get -y install \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor --batch --yes -o /usr/share/keyrings/docker-archive-keyring.gpg

echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

sudo apt-get update
sudo apt-get -y install docker-ce docker-ce-cli containerd.io

sudo usermod -aG docker "$(whoami)"
sudo systemctl enable docker.service
sudo systemctl enable containerd.service
sudo systemctl restart docker.service

sudo docker run hello-world

docker run -it --rm --name "bashit" -v "$(pwd):/usr/workspace" "bash:3.1" sh -c "cd /usr/workspace"
