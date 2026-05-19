#!/bin/bash
# -----------------------------------------------------------------------------
# Insider DevOps Case Study - Kubernetes Automation Deployment Script
# -----------------------------------------------------------------------------

set -e 

# Proje kök dizinine git
cd "$(dirname "$0")/.."

echo "🔌 1. Terminal Docker daemon'ı Minikube'a bağlanıyor..."
eval $(minikube docker-env)

echo "📦 2. Uygulama imajı Minikube içinde lokal olarak build ediliyor..."
docker build -t insider-app:local -f ./app/Dockerfile .

echo "🚀 3. Uygulama values-dev.yaml ayarlarıyla Kubernetes'e kuruluyor..."
helm upgrade --install insider-dev ./insider-app -f insider-app/values-dev.yaml

echo "📊 4. Dağıtım durumu kontrol ediliyor..."
helm status insider-dev

echo "=== 🎯 Uygulama Dağıtımı Başarıyla Tamamlandı! ==="

echo "🌐 [AĞ KÖPRÜSÜ] Linux Kernel seviyesinde IP yönlendirme aktif ediliyor..."
sudo sysctl -w net.ipv4.ip_forward=1

MINIKUBE_IP=$(minikube ip)
MINIKUBE_SUBNET=$(echo $MINIKUBE_IP | cut -d'.' -f1-3).0/24

echo "📡 [INBOUND IPTABLES] AWS Port 30080 -> Minikube IP yönlendirme kuralları işleniyor..."

# Kuralları temizle ve yeniden oluştur
sudo iptables -t nat -D PREROUTING -p tcp --dport 30080 -j DNAT --to-destination $MINIKUBE_IP:30080 2>/dev/null || true
sudo iptables -t nat -A PREROUTING -p tcp --dport 30080 -j DNAT --to-destination $MINIKUBE_IP:30080

sudo iptables -I FORWARD 1 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
sudo iptables -I FORWARD 1 -p tcp -d $MINIKUBE_IP --dport 30080 -j ACCEPT
sudo iptables -P FORWARD ACCEPT

echo "🚀 [OUTBOUND NAT] Masquerade kuralları uygulanıyor..."
sudo iptables -t nat -A POSTROUTING -s $MINIKUBE_SUBNET ! -d $MINIKUBE_SUBNET -j MASQUERADE 2>/dev/null || true

echo "📯 [DNS FIX] Minikube DNS adresleri enjekte ediliyor..."
minikube ssh "sudo sh -c 'echo \"nameserver 8.8.8.8\" > /etc/resolv.conf'"

echo "🎯 [BAŞARILI] Uygulama ağ özgürlüğüne kavuştu!"
echo "🌐 Canlı Adres: http://<AWS_ELASTIC_IP>:30080/healthz"