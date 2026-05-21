#!/bin/bash
# -----------------------------------------------------------------------------
# Insider DevOps Case Study - Minimal & Robust Deployment Script
# -----------------------------------------------------------------------------
set -e 

# Proje kök dizinine git
cd "$(dirname "$0")/.."

echo "🔌 1. Terminal Docker daemon'ı Minikube'a bağlanıyor..."
eval $(minikube docker-env)

echo "📦 2. Uygulama imajı Minikube içinde lokal olarak build ediliyor..."
docker build -t insider-app:local -f ./app/Dockerfile .

echo "🚀 3. Uygulama values-dev.yaml ayarlarıyla Kubernetes'e kuruluyor..."
helm upgrade --install insider-dev ./insider-app -f insider-app/values-dev.yaml --namespace insider-app

echo "📊 4. Dağıtım durumu kontrol ediliyor..."
helm status insider-dev --namespace insider-app

echo "=== 🎯 Uygulama Dağıtımı Başarıyla Tamamlandı! ==="
echo "🌐 Canlı Adres: http://<AWS_ELASTIC_IP>:30080/healthz"