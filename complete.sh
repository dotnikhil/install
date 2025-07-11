#!/bin/bash
sudo wget https://raw.githubusercontent.com/dotnikhil/install/refs/heads/main/jenkins.sh
sudo chmod 777 jenkins.sh
sudo sh jenkins.sh
sudo wget https://raw.githubusercontent.com/akshu20791/Deployment-script/main/k8s-master.sh
sudo chmod 777 k8s-master.sh
sudo sh k8s-master.sh
sudo usermod -aG docker jenkins
sudo cp /root/.kube/config .
sudo chown -R jenkins:jenkins /home/config
