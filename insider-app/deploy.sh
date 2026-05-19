#!/bin/bash
# -----------------------------------------------------------------------------
# Insider DevOps Case Study - Kubernetes Automation Deployment Script
# -----------------------------------------------------------------------------

set -e # Herhangi bir komut hata verirse scripti anında durdur

# Scriptin çalıştığı yer neresi olursa olsun, projenin kök dizinine odaklanıyoruz
cd "$(dirname "$0")/.."

echo "🚀 1. Prometheus CRD'leri Helm üzerinden native olarak yükleniyor..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts >/dev/null 2>&1 || true
helm repo update >/dev/null 2>&1
helm upgrade --install prometheus-crds prometheus-community/prometheus-operator-crds --create-namespace --namespace monitoring

echo "🔌 2. Terminal Docker daemon'ı Minikube'a bağlanıyor..."
eval $(minikube docker-env)

echo "📦 3. Uygulama imajı Minikube içinde lokal olarak build ediliyor..."
docker build -t insider-app:local -f ./app/Dockerfile .

echo "🚀 4. Uygulama values-dev.yaml ayarlarıyla Kubernetes'e kuruluyor..."
helm upgrade --install insider-dev ./insider-app -f insider-app/values-dev.yaml

echo "📊 5. Dağıtım durumu kontrol ediliyor..."
helm status insider-dev

echo "=== 🎯 Dağıtım Otomasyonu Başarıyla Tamamlandı! ==="

echo "🌐 [AĞ KÖPRÜSÜ] Linux Kernel seviyesinde IP yönlendirme aktif ediliyor..."
sudo sysctl -w net.ipv4.ip_forward=1

# Minikube IP'sini ve ağ maskesini dinamik alıyoruz
MINIKUBE_IP=$(minikube ip)
MINIKUBE_SUBNET=$(echo $MINIKUBE_IP | cut -d'.' -f1-3).0/24

echo "📡 [INBOUND IPTABLES] AWS Port 30080 -> Minikube IP yönlendirme kuralları işleniyor..."

# 1. Eski kuralları temizle
sudo iptables -t nat -D PREROUTING -p tcp --dport 30080 -j DNAT --to-destination $MINIKUBE_IP:30080 2>/dev/null || true
sudo iptables -D FORWARD -p tcp -d $MINIKUBE_IP --dport 30080 -j ACCEPT 2>/dev/null || true
sudo iptables -D FORWARD -p tcp -s $MINIKUBE_IP --sport 30080 -j ACCEPT 2>/dev/null || true
sudo iptables -D FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT 2>/dev/null || true

# 2. Yeni kurallar (PREROUTING)
sudo iptables -t nat -A PREROUTING -p tcp --dport 30080 -j DNAT --to-destination $MINIKUBE_IP:30080

# 3. VİP FORWARD KURALLARI (Docker'ı ezmek için -I 1 ile EN TEPEDEN ekliyoruz)
sudo iptables -I FORWARD 1 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
sudo iptables -I FORWARD 1 -p tcp -s $MINIKUBE_IP --sport 30080 -j ACCEPT
sudo iptables -I FORWARD 1 -p tcp -d $MINIKUBE_IP --dport 30080 -j ACCEPT
sudo iptables -P FORWARD ACCEPT

echo "🚀 [OUTBOUND NAT] Masquerade kuralı ekleniyor..."
sudo iptables -t nat -D POSTROUTING -s $MINIKUBE_SUBNET ! -d $MINIKUBE_SUBNET -j MASQUERADE 2>/dev/null || true
sudo iptables -t nat -A POSTROUTING -s $MINIKUBE_SUBNET ! -d $MINIKUBE_SUBNET -j MASQUERADE

echo "🔄 [HAIRPIN NAT] Çift yönlü iletişim çözülüyor..."
sudo iptables -t nat -D POSTROUTING -p tcp -d $MINIKUBE_IP --dport 30080 -j MASQUERADE 2>/dev/null || true
sudo iptables -t nat -A POSTROUTING -p tcp -d $MINIKUBE_IP --dport 30080 -j MASQUERADE

echo "📯 [DNS FIX] Minikube DNS adresleri enjekte ediliyor..."
minikube ssh "sudo sh -c 'echo \"nameserver 8.8.8.8\" > /etc/resolv.conf'"

echo "🎯 [BAŞARILI] Uygulama tamamen ağ özgürlüğüne kavuştu!"
echo "🌐 Canlı Adres: http://<AWS_ELASTIC_IP>:30080/healthz"