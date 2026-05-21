# Insider DevOps Case Study - End-to-End Delivery Documentation

Bu repo, Insider DevOps Case Study kapsamında geliştirilen Python tabanlı API uygulamasının, AWS bulut altyapısının (IaC), Kubernetes (Minikube) orkestrasyonunun ve izleme (Monitoring) sistemlerinin uçtan uca kurulum süreçlerini içerir.

Projede **Maliyet Bilinci (Cost-Awareness)**, **Yüksek Erişilebilirlik (High Availability)**, **Güvenlik (Security)** ve **Otomasyon (Automation)** prensipleri ana kılavuz olarak benimsenmiştir.

---

## 📈 Proje Yol Haritası (Milestones)

### 🔹 Milestone 1: Uygulama Geliştirme & Dockerization
* Python tabanlı, hafif, asenkron ve yüksek performanslı bir API geliştirildi.
* Uygulamanın her ortamda tutarlı çalışması için optimize edilmiş bir `Dockerfile` mimarisi kuruldu.

### 🔹 Milestone 1.5: Bulut Altyapısı & IaC (Terraform)
* AWS üzerinde tamamen kodla (IaC) güvenli bir network ve sunucu altyapısı kuruldu.
* Hesap kısıtlamalarını aşmak ve sistemi çökmez kılmak için OS seviyesinde SWAP Memory mimarisi optimize edildi.

### 🔹 Milestone 2: Kubernetes Orkestrasyonu & Helm Management
* Uygulamanın ham manifestolar yerine, ortam bağımsız (Dev/Prod) çalışabilen dinamik bir Helm Chart mimarisiyle dağıtım altyapısı hazırlandı.

---

# 🚀 INSIDER DEVOPS CASE STUDY - HOW TO RUN

Bu rehber, projenin GitHub'dan sıfır kopyasını çeken bir geliştiricinin, altyapıyı AWS üzerinde Terraform ile kurup, içeride Minikube ve Helm ile uygulamayı sıfırdan ayağa kaldırması için gereken tüm adımları kronolojik olarak içerir.

---

## 📁 Adım 1: Uygulama Ortamının Hazırlanması

Repoyu bilgisayarınıza klonladıktan sonra ilk olarak uygulama klasörüne geçip gerekli çevre değişkenlerini ve bağımlılıkları kuruyoruz:

```bash
# 1. Uygulama klasörüne geçiş
cd app

# 2. Port bilgisini içeren .env dosyasının oluşturulması
echo "APP_PORT=8080" > .env

# 3. Sanal ortamın kurulup bağımlılıkların yüklenmesi
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
cd ..
```

## 🗺️ Adım 2: AWS Üzerinde Altyapının Kurulması (Terraform)

AWS üzerinde gerekli sunucu (EC2) ve network kaynaklarını (VPC, Security Group vb.) ayağa kaldırmak için Terraform kullanıyoruz.

### 1️⃣ `terraform.tfvars` Dosyasının Hazırlanması

`terraform/` klasörüne girin ve aşağıdaki içerikle bir `terraform.tfvars` dosyası oluşturun:

```hcl
# terraform/terraform.tfvars

my_ip    = "xx.xx.xx.xx"       # Kendi lokal IP adresiniz
key_name = "your-aws-key-name" # AWS panelindeki mevcut SSH Key (.pem) adınız
```

- `my_ip`: Kendi internet IP adresiniz
- `key_name`: AWS üzerinde oluşturduğunuz SSH Key Pair adı

---

### 🔑 2️⃣ SSH Anahtarının (.pem) Hazırlanması

AWS panelinden indirdiğiniz `.pem` dosyasını `terraform/` klasörünün içine taşıyın.

Daha sonra Linux/macOS sistemlerde güvenlik hatası almamak için dosya izinlerini kısıtlayın:

```bash
chmod 400 your-aws-key-name.pem
```

---

### ☁️ 3️⃣ AWS Kaynaklarının Oluşturulması

Aşağıdaki komutları sırasıyla çalıştırın:

```bash
cd terraform

terraform init
terraform plan
terraform apply -auto-approve

cd ..
```

Kurulum tamamlandığında Terraform size EC2 sunucusunun `public_ip` bilgisini verecektir.

---

# 💻 Adım 3: AWS Sunucusuna Bağlantı & Otomatik Altyapı Kurulumu

Bu projede **Separation of Concerns** prensibi uygulanmıştır.

Sunucu altyapısı:

- Docker
- Minikube
- Kubernetes
- IPTables NAT kuralları
- Namespace yapıları
- SWAP ayarları

tamamen Terraform tarafından tetiklenen `install_dependencies.sh` (Cloud-Init / User-Data) ile otomatik olarak kurulmaktadır.

---

### 🔐 1️⃣ Sunucuya SSH ile Bağlanma

Terraform çıktısındaki public IP adresini kullanarak EC2 sunucusuna bağlanın:

```bash
ssh -i terraform/your-aws-key-name.pem ubuntu@<EC2_PUBLIC_IP>
```

---

### ⏳ 2️⃣ Cloud-Init Kurulum Sürecini İzleme (Opsiyonel)

Sunucuya ilk girişte Kubernetes, Docker ve ağ yönlendirmeleri arka planda kuruluyor olacaktır.

Kurulum loglarını canlı izlemek için:

```bash
tail -f /var/log/cloud-init-output.log
```

Aşağıdaki mesajı gördüğünüzde altyapı tamamen hazırdır:

```bash
=== Setup Completed Successfully! ===
```

Çıkmak için:

```bash
CTRL + C
```

---

### 📥 3️⃣ Projenin Sunucuya Klonlanması

```bash
git clone https://github.com/emretaskend22/insider_devops_case_study.git

cd insider_devops_case_study
```

---

# ☸️ Adım 4: Uygulama Dağıtımı (Helm & Automation)

Altyapı bileşenleri (Docker, Kubernetes, Namespace, CRD, NAT vb.) zaten Cloud-Init ile hazırlandığı için deployment süreci tamamen stateless hale getirilmiştir.

Dağıtım yalnızca uygulamaya odaklanır.

---

### 🚀 1️⃣ Tek Komutla Deployment

Deployment scriptine çalıştırma izni verin ve başlatın:

```bash
chmod +x ./insider-app/deploy.sh

./insider-app/deploy.sh
```

Bu script:

- Docker image build eder
- Image'ı Minikube içerisine yükler
- Helm chart deploy eder
- `values-dev.yaml` ayarlarını uygular
- Uygulamayı `monitoring` namespace'ine deploy eder

---

### ✅ 2️⃣ Deployment Doğrulama

Pod'un başarıyla ayağa kalktığını doğrulayın:

```bash
kubectl get pods -n insider-app
```

Aşağıdakine benzer bir çıktı görmelisiniz:

```bash
NAME                           READY   STATUS    RESTARTS   AGE
insider-dev-xxxxxxxxxx-xxxxx   1/1     Running   0          30s
```

`STATUS: Running` ve `READY: 1/1` gördüğünüzde uygulama başarıyla deploy edilmiş demektir. 🎉

---

# 🌐 Adım 5: Canlı Erişim Testi

Kubernetes cluster'ı EC2 üzerinde izole bir Minikube ağı içerisinde çalışmaktadır.

Cloud-Init aşamasında kernel seviyesinde kalıcı `iptables NAT` kuralları tanımlandığı için:

- `kubectl port-forward`
- `minikube service`
- `LoadBalancer`

gibi geçici çözümlere ihtiyaç duyulmaz.

Uygulamaya doğrudan EC2 public IP üzerinden erişebilirsiniz:

```bash
http://<AWS_ELASTIC_IP>:30080/healthz
```

Başarılı sonuç:

```json
{"status":"healthy"}
```

Bu çıktıyı görüyorsanız sistem tamamen canlıdır 🚀

## 🚀 Adım 5: Production CI/CD Pipeline (GitHub Actions)
 
`main` branch'ine yapılan her push ve merge işleminde; test, güvenlik taraması (Trivy, GitLeaks, Ruff) ve AWS sunucusuna sıfır kesintiyle (Zero-Downtime Rolling Update) otomatik dağıtım yapılır.
 
### 🔐 1. Güvenlik ve Sır İzolasyonu (Bootstrap)
 
Siber güvenlik standartları gereği GHCR token'ı SSH tüneli üzerinden cleartext olarak taşınmaz. Bunun yerine Kubernetes'e image pull yetkisi **bir kez manuel olarak** tanımlanır:
 
```bash
kubectl create secret docker-registry ghcr-secret \
  --docker-server=ghcr.io \
  --docker-username="<YOUR_GITHUB_USERNAME>" \
  --docker-password="<YOUR_GITHUB_PAT>" \
  --docker-email="<YOUR_GITHUB_EMAIL>"
```
 
> 🔒 Bu secret cluster hafızasına güvenli şekilde gömüldükten sonra pipeline hiçbir hassas bilgi taşımaz.
 
### ⚙️ 2. GitHub Secrets Kurulumu
 
Reponuzun **Settings → Secrets and variables → Actions** sayfasına giderek şu 5 parametreyi tanımlayın:
 
| Secret Key | Açıklama | Nereden Alınır? |
|---|---|---|
| `AWS_ROLE_ARN` | GitHub Actions OIDC Rolü | Terraform çıktısı |
| `EC2_SG_ID` | AWS Security Group ID | Terraform çıktısı veya AWS Console |
| `EC2_HOST` | Sunucunun Public IP Adresi | Terraform çıktısı (`public_ip`) |
| `EC2_USERNAME` | Sunucu kullanıcı adı | `ubuntu` |
| `EC2_SSH_KEY` | SSH Private Key | `.pem` dosyasının tüm içeriği |
 
### 🚀 3. Otomatik Dağıtım ve Zero-Downtime Testi
 
`main`'e PR merge'leyin. Pipeline şu zinciri otomatik çalıştırır:
 
1. **Linter & Secrets Scan** — Ruff kod kalitesini, GitLeaks sır sızıntısını denetler
2. **Docker Build & Trivy Scan** — İmaj derlenir, Trivy CRITICAL/HIGH açık tarar, temiz imaj GHCR'a push'lanır
3. **Dynamic IP Whitelisting** — Runner'ın anlık IP'si bulunur, Security Group'a sadece o saniye SSH izni eklenir
4. **Automated Rolling Update** — Helm Chart `values-prod.yaml` ile güncellenir, yeni pod'lar ayağa kalkar
5. **Dynamic Firewall Revoke** — Dağıtım başarılı olsa da olmasa da (`if: always()`) kapı anında kilitlenir
Pod'ların canlı durumunu izlemek için:
 
```bash
kubectl get pods -w
```
 
Yeni pod'lar `1/1 Running` olduğu saniye eski pod'lar sıfır kesintiyle temizlenir.

## 📊 Adım 6: Observability ve Otomatik Metrik Hattı (Day 4)

Uygulamanın performansını, anlık istek sayılarını (RPS), hata oranlarını ve gecikme sürelerini (Latency) canlı izlemek ve kritik durumlarda alarm üretebilmek adına sisteme tam otomatik bir **Observability (İzlenebilirlik)** katmanı entegre edilmiştir.

### 🧠 Mimari Kararlar (ADR & Best Practices)
* **Bellek Optimizasyonu (Swap):** Prometheus stack'in `t3.small` (2GB RAM) üzerinde stabil çalışması için 4GB SWAP alanı devreye alınmış, bulut maliyetleri Free Tier sınırında tutulmuştur.
* **Declarative GitOps (Helm Templates Integration):** `servicemonitor.yaml` ve `alert-rule.yaml` (Alarm kuralı) dosyaları, uygulamadan bağımsız manuel yönetilmek yerine doğrudan `./insider-app/templates/` klasörüne dahil edilmiştir. Bu sayede CI/CD pipeline her tetiklendiğinde izleme ve alarm mekanizmaları uygulama ile birlikte **tam otomatik (zero-touch)** olarak deploy edilir.

### 🛠️ Altyapı Hazırlığı (Sunucuda Bir Kez Çalıştırılır)
Monitoring core bileşenlerini (Prometheus ve Grafana) ayağa kaldırmak için sunucu içerisinde şu komutlar koşturulur:
```bash
# Monitoring için izole namespace oluşturulması
kubectl create namespace monitoring

# Kube-Prometheus-Stack Helm deposunun eklenmesi ve kurulumu
helm repo add prometheus-community [https://prometheus-community.github.io/helm-charts](https://prometheus-community.github.io/helm-charts)
helm repo update
helm upgrade --install prometheus-stack prometheus-community/kube-prometheus-stack -n monitoring


---

## 🛠️ Detaylı Aşama Analizleri & "Neden-Niçin" Günlüğü (ADR)

### 📌 AŞAMA 1: Uygulama Geliştirme & Dockerization

* **Uygulama Seçimi:** Projenin core (çekirdek) API katmanı için Python dilinin hafif, asenkron ve yüksek performanslı modern kütüphaneleri tercih edilmiştir. API, operasyonel yük oluşturmamak ve yatayda kusursuz ölçeklenebilmek adına **Stateless (Bağımsız/Hafızada)** bir mimariyle kurgulanmıştır.
* **Dockerfile Stratejisi:** İmaj boyutunu minimumda tutmak, saldırı yüzeyini azaltmak (Security) ve build sürelerini optimize etmek adına `Dockerfile` içerisinde optimize edilmiş imaj taktikleri kullanılmıştır. Sadece uygulamanın çalışması için gerekli olan runtime bağımlılıkları production imajına dahil edilmiştir.

### 📌 AŞAMA 1.5: Bulut Altyapısı & IaC (Terraform)

#### 1. Neden `t3.small` Instance Tipi Seçildi?
* **Problem:** Minikube/Kubernetes kontrol düzleminin (control plane) kararlı çalışabilmesi için en az 2 vCPU ve 2GB-4GB RAM gerekmektedir (`t3.medium`). Ancak kişisel/yeni AWS hesaplarındaki katı **Free Tier vCPU kota kısıtlamaları (On-Demand vCPU blocking)** nedeniyle `t3.medium` sunucu istekleri AWS API katmanında reddedilmiştir.
* **Çözüm:** Teslimat (delivery) odağını kaybetmemek ve AWS hesap limitlerine tam uyum sağlamak adına, hesaba tanımlı ve onaylı olan en optimum model **`t3.small` (2 vCPU, 2GB RAM)** seçilmiştir.

#### 2. Neden İşletim Sistemi Seviyesinde SWAP Memory Kuruldu?
* **Problem:** `t3.small` sunucusunun sağladığı 2GB fiziksel RAM, Minikube'un ayağa kalkması için sınırda bir değerdir. İlerleyen aşamalarda sisteme eklenecek olan Uygulama Pod'ları, Prometheus ve Grafana araçları fiziksel RAM sınırını aşarak **OOMKilled (Out Of Memory)** hatalarına ve sunucunun tamamen kilitlenmesine yol açacaktı.
* **Çözüm:** Fiziksel RAM yetersizliğini aşmak için 20GB'lık `gp3` diskin 4GB'lık kısmı **SWAP (Sanal Bellek)** alanı olarak konfigüre edilmiştir. Bu sayede sunucu toplam belleği yapay olarak 6GB seviyesine çekilmiştir. Geçici kaynak patlamalarında (burst) sistemin çökmesi engellenmiş, **Fail-Safe** ve yüksek erişilebilir bir mikro-altyapı simüle edilmiştir. (Kubernetes v1.28+ standartlarına tam uyum sağlanmıştır).

#### 3. Neden Ağ Güvenliği (Security Group) Sıkılaştırıldı?
* **Problem:** Altyapının internete açık olması, kaba kuvvet (brute-force) saldırılarına ve port tarama risklerine zemin hazırlar.
* **Çözüm:** Güvenlik duvarında (Security Group) HTTP (80) trafiği tüm dünyaya açık bırakılırken; kritik ve hassas olan **SSH (22)** portu ile **Kubernetes NodePort (30000-32767)** aralığı, Terraform değişkenleri (`var.my_ip`) kullanılarak **sadece geliştiricinin anlık IP adresine (`/32`) kilitlenmiştir.**

#### 4. Otomasyon (Configuration as Code)
* Sunucu provizyon edildikten sonra içeride yapılan tüm operasyonel adımlar (SWAP aktivasyonu, Docker kurulumu, kullanıcı izinleri ve optimize edilmiş Minikube cluster başlangıcı) `terraform/scripts/install_dependencies.sh` dosyası altında scriptleştirilerek sistemin tekrar üretilebilir (reproducible) olması sağlanmıştır.

### 📌 AŞAMA 2: Kubernetes Orkestrasyonu & Helm Management

### 📊 2.1 Helm Chart Architecture (Raw Manifest vs. Helm)

Projenin ölçeklenebilir ve yönetilebilir olması amacıyla Kubernetes üzerinde ham (raw) manifestolar kullanmak yerine tamamen özelleştirilmiş bir **Helm Chart** (`insider-app`) mimarisi kurulmuştur.

* **Sadelik ve Stateless Yapı:** Python FastAPI uygulamamız tamamen stateless (veritabanından bağımsız) ve herhangi bir credential (şifre/token) içermediği için, güvenlik mimarisinde "best practice" olarak repoya içi boş/gereksiz bir `Secret` objesi eklenmemiştir.
* **ConfigMap Enjeksiyonu:** Uygulamanın çalışacağı port bilgisi (`APP_PORT`) `values.yaml` üzerinden merkezi olarak yönetilmekte ve `templates/configmap.yaml` aracılığıyla pod içerisine dinamik çevre değişkeni (environment variable) olarak enjekte edilmektedir. Bu sayede yazılım koduna dokunmadan konfigürasyon esnekliği sağlanmıştır.
* **Servis Yönetimi:** Pod'lara gelecek olan iç ve dış trafiği dengelemek adına kurumsal standartta bir `Service` şablonu kurgulanmıştır.