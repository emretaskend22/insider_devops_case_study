# Insider-App: End-to-End DevOps & Observability Case Study

Bu proje, Python (FastAPI) tabanlı bir mikroservisin sıfırdan AWS bulut altyapısına kadar uzanan tam otomatik (CI/CD), izlenebilir (Observability) ve güvenli (Security-Aware) dağıtım sürecini gösteren uçtan uca bir DevOps vaka çalışmasıdır. 

Sistem, AWS Free Tier sınırları içerisinde (`t3.small`) Kubernetes (Minikube) çalıştıracak şekilde optimize edilmiş ve "Infrastructure as Code" (Terraform, Track A) ile inşa edilmiştir.

## 🏗️ Architecture Overview

![Architecture Diagram](docs/architecture_diagram.png)

## 🛠️ Tech Stack
* **Application:** Python, FastAPI, Uvicorn
* **Containerization:** Docker (Multi-stage, Non-root user)
* **Infrastructure as Code (IaC):** Terraform
* **Orchestration:** Kubernetes (Minikube), Helm
* **CI/CD:** GitHub Actions (OIDC, Dynamic IP Whitelisting, Trivy)
* **Observability:** Prometheus, Grafana, Alertmanager

---

# 🚀 INSIDER DEVOPS CASE STUDY - HOW TO RUN

---

## 📁 Adım 1: Projeyi Klonlama

Altyapı kurulumuna başlamak için projeyi bilgisayarınıza indirin ve ana dizine geçin:

```bash
git clone [https://github.com/emretaskend22/insider_devops_case_study.git](https://github.com/emretaskend22/insider_devops_case_study.git)
cd insider_devops_case_study
cd app

# 2. Port bilgisini içeren .env dosyasının oluşturulması
echo "APP_PORT=8080" > .env
```

## 🗺️ Adım 2: AWS Altyapısının Kurulması (Terraform)

AWS üzerindeki sunucu (EC2), ağ ve güvenlik kaynakları (IaC) Terraform ile yönetilmektedir.

**1. Konfigürasyon:** `terraform/` dizinine geçin ve kendi değişkenlerinizi tanımlamak için bir `terraform.tfvars` dosyası oluşturun:

```hcl
# terraform/terraform.tfvars
my_ip    = "xx.xx.xx.xx"       # Kendi lokal IP adresiniz
key_name = "your-aws-key-name" # AWS panelindeki mevcut SSH Key (.pem) adınız
github_repo = "username/repo"     # Kendi GitHub repo yolunuz (OIDC için)
```
---

### 🔑 2️⃣ SSH Anahtarının (.pem) Hazırlanması

AWS konsolundan indirdiğiniz `.pem` dosyasını `terraform/` klasörüne taşıyın, ardından izinlerini kısıtlayın:

```bash
chmod 400 your-aws-key-name.pem
```

> **Not:** Bu adım Linux/macOS için zorunludur; aksi hâlde SSH bağlantısı sırasında izin hatası alırsınız.

---

### ☁️ 3️⃣ AWS Kaynaklarının Oluşturulması

Aşağıdaki komutları sırasıyla çalıştırın:

```bash
cd terraform

terraform init       # Provider'ları ve modülleri indirir
terraform plan       # Oluşturulacak kaynakları önizler
terraform apply -auto-approve  # Kaynakları oluşturur

cd ..
```

Kurulum tamamlandığında Terraform, EC2 sunucusunun `public_ip` adresini çıktı olarak gösterecektir.

---

# 💻 Adım 3: AWS Sunucusuna Bağlantı & Otomatik Altyapı Kurulumu

### 🔐 1️⃣ Sunucuya SSH ile Bağlanma

Terraform çıktısındaki public IP adresini kullanarak EC2 sunucusuna bağlanın:

```bash
ssh -i terraform/your-aws-key-name.pem ubuntu@<EC2_PUBLIC_IP>
```

---

### ⏳ 2️⃣ Cloud-Init Kurulum Sürecini İzleme (Opsiyonel)

Sunucuya ilk girişte Kubernetes, Docker ve ağ yönlendirmeleri arka planda kurulmaya devam ediyor olabilir. Kurulum loglarını canlı izlemek için:

```bash
tail -f /var/log/cloud-init-output.log
```

Aşağıdaki mesajı gördüğünüzde altyapı tamamen hazırdır:

```
=== Setup Completed Successfully! ===
```

---

### 📥 3️⃣ Projenin Sunucuya Klonlanması

```bash
git clone https://github.com/emretaskend22/insider_devops_case_study.git
cd insider_devops_case_study
```

---

# ☸️ Adım 4: Uygulama Dağıtımı (Helm & Automation)

Altyapı bileşenleri (Docker, Kubernetes, Namespace, CRD, NAT vb.) Cloud-Init tarafından hazırlandığından deployment süreci yalnızca uygulamaya odaklanır.

---

### 🚀 1️⃣ Tek Komutla Deployment

Deployment scriptine çalıştırma izni verin ve başlatın:

```bash
chmod +x ./insider-app/deploy.sh
./insider-app/deploy.sh
```

---

### ✅ 2️⃣ Deployment Doğrulama

Pod'un başarıyla ayağa kalktığını doğrulayın:

```bash
kubectl get pods -n insider-app
```

Beklenen çıktı:

```
NAME                           READY   STATUS    RESTARTS   AGE
insider-dev-xxxxxxxxxx-xxxxx   1/1     Running   0          30s
```

`STATUS: Running` ve `READY: 1/1` görüyorsanız uygulama başarıyla deploy edilmiştir. 🎉

---

# 🌐 Adım 5: Canlı Erişim Testi
Uygulamaya doğrudan EC2 public IP üzerinden erişebilirsiniz:

```
http://<AWS_ELASTIC_IP>:30080/healthz
```

Beklenen yanıt:

```json
{"status":"healthy"}
```

Bu çıktıyı görüyorsanız sistem tamamen canlıdır. 🚀


# 🚀 Adım 6: Production CI/CD Pipeline (GitHub Actions)

### 🔐 1️⃣ Güvenlik ve Secret İzolasyonu (Bootstrap)

Güvenlik standartları gereği GHCR token'ı SSH üzerinden cleartext olarak taşınmaz. Bunun yerine Kubernetes cluster'ına image pull yetkisi yalnızca bir kez manuel olarak tanımlanır.

Aşağıdaki komutu `insider-app` namespace'i için çalıştırın:

```bash
kubectl create secret docker-registry ghcr-secret \
  --namespace insider-app \
  --docker-server=ghcr.io \
  --docker-username="<YOUR_GITHUB_USERNAME>" \
  --docker-password="<YOUR_GITHUB_PAT>" \
  --docker-email="<YOUR_GITHUB_EMAIL>"
```

Bu işlemden sonra Kubernetes cluster'ı GHCR'dan private image çekebilir hale gelir. CI/CD pipeline'ı deployment sırasında hassas credential taşımaz; secret cluster içinde güvenli şekilde saklanır.

---

### ⚙️ 2️⃣ GitHub Actions Secrets Kurulumu

Repository'de aşağıdaki sayfaya gidin:

```
Settings → Secrets and variables → Actions
```

Aşağıdaki secret'ları tanımlayın:

| Secret Key | Açıklama |
|---|---|
| `AWS_ROLE_ARN` | GitHub Actions OIDC IAM Role ARN |
| `EC2_SG_ID` | EC2 instance Security Group ID |
| `EC2_HOST` | EC2 Public IP adresi |
| `EC2_USERNAME` | SSH kullanıcı adı (`ubuntu`) |
| `EC2_SSH_KEY` | `.pem` private key içeriği |

---

### 📊 3️⃣ Rolling Update Sürecini İzleme

Deployment sırasında pod geçişlerini canlı izlemek için:

```bash
kubectl get pods -n insider-app -w
```

Yeni pod'lar `READY: 1/1` ve `STATUS: Running` durumuna geçtiği anda Kubernetes eski pod'ları otomatik olarak kaldırır. Bu süreç boyunca uygulama kesintisiz hizmet vermeye devam eder. 🚀

# 📊 Adım 7: Observability ve Grafana Monitoring

---

### 🛠️ 1️⃣ Prometheus & Grafana Kurulumu

Namespace ve Prometheus CRD'leri Cloud-Init tarafından önceden hazırlandığından doğrudan monitoring stack kurulumuna geçebilirsiniz.

EC2 sunucusuna SSH ile bağlandıktan sonra aşağıdaki komutları çalıştırın:

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm upgrade --install prometheus-stack \
  prometheus-community/kube-prometheus-stack \
  --namespace monitoring
```

Kurulum tamamlandıktan sonra Prometheus, Grafana ve exporter servisleri `monitoring` namespace'i altında ayağa kalkacaktır.

---

### 🌐 2️⃣ Grafana Arayüzüne Erişim

Grafana servisine erişmek için port-forward başlatın:

```bash
kubectl port-forward -n monitoring svc/prometheus-stack-grafana 30000:80 --address 0.0.0.0
```

Ardından tarayıcıdan erişin:

```
http://<AWS_ELASTIC_IP>:30000
```

---

### 🔑 3️⃣ Grafana Login Bilgileri

Kullanıcı adı `admin`'dir. Şifreyi almak için:

```bash
kubectl get secret \
  --namespace monitoring \
  prometheus-stack-grafana \
  -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
```

### 📈 4️⃣ FastAPI Metrics Dashboard Import

Grafana arayüzüne giriş yaptıktan sonra aşağıdaki dashboard ID'lerinden birini import ederek FastAPI uygulama metriklerini canlı izleyebilirsiniz:

| Dashboard | ID |
|---|---|
| FastAPI Observability | `16110` |
| FastAPI Full Observability | `25040` |

Import için: **Dashboards → Import → Dashboard ID**

---

### 📊 5️⃣ İzlenebilen Metrikler

Grafana dashboard'ları üzerinden aşağıdaki metrikler canlı izlenebilir:

- HTTP request rate (RPS), latency, error rate ve status code dağılımı
- Endpoint bazlı trafik analizi
- CPU / Memory kullanımı
- Kubernetes pod sağlık durumu ve node kaynak tüketimi


---

## 📚 Operasyonel Dokümantasyon

Sistemin yönetimi ve alınan mimari kararlar için `docs/` klasöründeki belgelere göz atabilirsiniz:
* [**RUNBOOK.md**](docs/RUNBOOK.md): Yeniden başlatma, geri alma (rollback) ve log inceleme prosedürleri.
* [**SECURITY.md**](docs/SECURITY.md): Non-root kullanıcı, RBAC ve secret yönetimi stratejileri.
* [**ADR (Architecture Decision Records)**](docs/adr/): Kullanılan teknolojilerin ve altyapı seçimlerinin gerekçeleri.

---
**Author:** Emre Taşkend