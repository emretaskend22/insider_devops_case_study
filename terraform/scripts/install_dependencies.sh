#!/bin/bash
# -----------------------------------------------------------------------------
# Insider DevOps Case Study - Server Provisioning Script (Cloud-Init & Infrastructure)
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
grep -q "alias kubectl='minikube kubectl --'" /home/ubuntu/.bashrc || echo "alias kubectl='minikube kubectl --'" >> /home/ubuntu/.bashrc
chown ubuntu:ubuntu /home/ubuntu/.bashrc

echo "=== 6. Starting Minikube Cluster (As Ubuntu User) ==="
sudo -i -u ubuntu sg docker -c "minikube start --driver=docker --memory=1800mb --cpus=2"
sudo -i -u ubuntu sg docker -c "minikube addons enable metrics-server"

echo "=== 7. Creating Necessary Namespaces (Infrastructure Preparation) ==="
# Uygulama deploy olmadan önce evini hazırlıyoruz
sudo -i -u ubuntu sg docker -c "minikube kubectl -- create namespace monitoring --dry-run=client -o yaml | minikube kubectl -- apply -f -"

echo "=== 8. Configuring Minikube Network & IPTables (Infrastructure Level) ==="
# Minikube IP'sini root kullanıcısına çekiyoruz
MINIKUBE_IP=$(sudo -i -u ubuntu sg docker -c "minikube ip")
MINIKUBE_SUBNET=$(echo $MINIKUBE_IP | cut -d'.' -f1-3).0/24

# Ağ köprüsünü ve yönlendirmeleri bir kereye mahsus altyapıda kuruyoruz
sudo iptables -t nat -A PREROUTING -p tcp --dport 30080 -j DNAT --to-destination $MINIKUBE_IP:30080
sudo iptables -I FORWARD 1 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
sudo iptables -I FORWARD 1 -p tcp -d $MINIKUBE_IP --dport 30080 -j ACCEPT
sudo iptables -P FORWARD ACCEPT
sudo iptables -t nat -A POSTROUTING -s $MINIKUBE_SUBNET ! -d $MINIKUBE_SUBNET -j MASQUERADE 2>/dev/null || true

echo "=== 9. Fixing Minikube DNS ==="
sudo -i -u ubuntu sg docker -c "minikube ssh \"sudo sh -c 'echo nameserver 8.8.8.8 > /etc/resolv.conf'\""

echo "=== Setup Completed Successfully! ==="