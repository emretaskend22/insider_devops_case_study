#!/bin/bash
# -----------------------------------------------------------------------------
# Insider DevOps Case Study - Server Provisioning Script (Cloud-Init & Production-Ready)
# -----------------------------------------------------------------------------
set -e 

echo "=== 1. Configuring SWAP Memory (4GB) ==="
if [ ! -f /swapfile ]; then
    fallocate -l 4G /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    echo '/swapfile none swap sw 0 0' >> /etc/fstab
fi

echo "=== 2. Enabling Permanent Linux Kernel IP Forwarding ==="
grep -q "net.ipv4.ip_forward=1" /etc/sysctl.conf || echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sysctl -p

echo "=== 3. Updating System Packages & Installing Docker, Git, Conntrack ==="
apt-get update -y
apt-get install docker.io git conntrack -y
usermod -aG docker ubuntu

echo "=== 4. Installing Minikube & Helm ==="
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
install minikube-linux-amd64 /usr/local/bin/minikube
rm minikube-linux-amd64

curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
rm get_helm.sh

echo "=== 5. Configuring kubectl alias for Ubuntu user ==="
# Sadece yoksa ekle (duplicate önlemek için)
grep -q "alias kubectl='minikube kubectl --'" /home/ubuntu/.bashrc || echo "alias kubectl='minikube kubectl --'" >> /home/ubuntu/.bashrc
chown ubuntu:ubuntu /home/ubuntu/.bashrc

echo "=== 6. Starting Minikube Cluster (As Ubuntu User) ==="
sudo -i -u ubuntu sg docker -c "minikube start --driver=docker --memory=1800mb --cpus=2"
sudo -i -u ubuntu sg docker -c "minikube addons enable metrics-server"

echo "=== Setup Completed Successfully! ==="