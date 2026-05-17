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