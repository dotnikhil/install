#!/bin/bash
sudo wget https://raw.githubusercontent.com/dotnikhil/install/refs/heads/main/jenkins.sh
sudo chmod 777 jenkins.sh
sudo sh jenkins.sh
apt install docker.io -y
sudo wget https://raw.githubusercontent.com/dotnikhil/install/refs/heads/main/eks.sh
chmod 777 eks.sh
sudo sh eks.sh
sudo usermod -aG docker jenkins
