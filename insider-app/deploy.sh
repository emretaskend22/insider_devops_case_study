#!/bin/bash
# -----------------------------------------------------------------------------
# Insider DevOps Case Study - Kubernetes Automation Deployment Script
# -----------------------------------------------------------------------------

set -e # Herhangi bir komut hata verirse scripti anında durdur

# Scriptin çalıştığı yer neresi olursa olsun, her zaman projenin kök dizinine (insider_devops_case_study) odaklanmasını sağlıyoruz
cd "$(dirname "$0")/.."

echo "🔌 1. Terminal Docker daemon'ı Minikube'a bağlanıyor..."
eval $(minikube docker-env)

echo "📦 2. Uygulama imajı Minikube içinde lokal olarak build ediliyor..."
docker build -t insider-app:local ./app

echo "🚀 3. Uygulama values-dev.yaml ayarlarıyla Kubernetes'e kuruluyor / güncelleniyor..."
helm upgrade --install insider-dev ./insider-app -f insider-app/values-dev.yaml

echo "📊 4. Dağıtım durumu kontrol ediliyor..."
helm status insider-dev

echo "=== 🎯 Dağıtım Otomasyonu Başarıyla Tamamlandı! ==="

echo "🌐 [AĞ KÖPRÜSÜ] Linux Kernel seviyesinde IP yönlendirme aktif ediliyor..."
sudo sysctl -w net.ipv4.ip_forward=1

echo "📡 [IPTABLES] AWS Port 30080 -> Minikube IP yönlendirme kuralları işleniyor..."
# Minikube IP'sini dinamik alıyoruz ki yarın öbür gün IP değişirse script patlamasın!
MINIKUBE_IP=$(minikube ip)

# Eski kurallar varsa temizle (duplicate önlemek için)
sudo iptables -t nat -D PREROUTING -p tcp --dport 30080 -j DNAT --to-destination $MINIKUBE_IP:30080 2>/dev/null || true
sudo iptables -D FORWARD -p tcp -d $MINIKUBE_IP --dport 30080 -j ACCEPT 2>/dev/null || true

# Yeni kuralları çak
sudo iptables -t nat -A PREROUTING -p tcp --dport 30080 -j DNAT --to-destination $MINIKUBE_IP:30080
sudo iptables -A FORWARD -p tcp -d $MINIKUBE_IP --dport 30080 -j ACCEPT
sudo iptables -P FORWARD ACCEPT

echo "🎯 [BAŞARILI] Uygulama dış dünyaya tamamen açıldı! Adres: http://<AWS_ELASTIC_IP>:30080/healthz"