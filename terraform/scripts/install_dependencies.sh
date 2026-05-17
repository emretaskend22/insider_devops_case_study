#!/bin/bash
# -----------------------------------------------------------------------------
# Insider DevOps Case Study - Server Provisioning Script
# This script configures SWAP memory, installs Docker, and initializes Minikube.
# -----------------------------------------------------------------------------

set -e # Herhangi bir komut hata verirse scripti durdur

echo "=== 1. Configuring SWAP Memory (4GB) ==="
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

echo "=== 2. Updating System Packages & Installing Docker ==="
sudo apt-get update -y
sudo apt-get install docker.io -y
sudo usermod -aG docker $USER

echo "=== 3. Installing Minikube ==="
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
rm minikube-linux-amd64

echo "=== 4. Starting Minikube Cluster ==="
# Optimized resources for t3.small instance using SWAP
minikube start --driver=docker --memory=1800mb --cpus=2

echo "=== Setup Completed Successfully! ==="