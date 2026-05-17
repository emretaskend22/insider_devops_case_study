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

# 🚀 INSIDER DEVOPS CASE STUDY - HOW TO WORK

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

---

## 🗺️ Adım 2: Altyapının AWS Üzerinde Kurulması (Terraform)

AWS üzerinde gerekli sunucu (EC2) ve network (VPC, Security Group) kaynaklarını ayağa kaldırmak için Terraform dizinine geçiyoruz.

### 1. `terraform.tfvars` Dosyasının Hazırlanması

`terraform/` klasörünün içerisine girin ve hem kendi lokal IP adresinizi hem de AWS hesabınızda bulunan SSH anahtarınızın (.pem) adını tanımlayacağınız bir `terraform.tfvars` dosyası oluşturun:

```hcl
# terraform/terraform.tfvars
my_ip    = "xx.xx.xx.xx"       # Kendi lokal IP adresiniz
key_name = "your-aws-key-name" # AWS panelindeki mevcut SSH Key (.pem) adınız
```

### 🔑 2. SSH Anahtarının (`.pem`) Hazırlanması

AWS panelinden indirdiğiniz `your-aws-key-name.pem` dosyasını, Terraform komutlarını koşturacağınız yerle aynı dizine (`terraform/` klasörünün içine) taşıyın. Ardından, Linux/Mac sistemlerde SSH bağlantısı sırasında güvenlik hatası (`Unprotected Private Key File`) almamak için bu anahtarın dosya izinlerini kısıtlayın:

```bash
# Sadece dosya sahibinin okuyabilmesi için izinleri 400 yapıyoruz (Kritik Adım!)
chmod 400 your-aws-key-name.pem
```

### 3. Altyapının Ayağa Kaldırılması

Aşağıdaki komutları sırasıyla çalıştırarak AWS kaynaklarını oluşturun:

```bash
terraform init
terraform plan
terraform apply -auto-approve
cd ..
```

Komut başarıyla tamamlandığında, Terraform çıktı (output) olarak sunucunun `public_ip` adresini ekrana basacaktır.

---

## 💻 Adım 3: AWS Sunucusuna Bağlantı ve Temel Kurulumlar

### 1. Sunucuya SSH ile Giriş Yapma

Terraform'un çıktı olarak verdiği IP adresini ve `terraform/` klasörünün içine koyup izinlerini ayarladığınız o güvenli anahtarı kullanarak sunucuya bağlanın:

```bash
ssh -i terraform/your-aws-key-name.pem ubuntu@<EC2_PUBLIC_IP>
```

### 2. Projenin Sunucu İçerisinde Klonlanması

Sunucu içerisine başarıyla girdikten sonra, en güncel kodları sunucu diskine çekip proje klasörüne giriş yapın:

```bash
git clone https://github.com/emretaskend22/insider_devops_case_study.git
cd insider_devops_case_study
```

### 🛠️ 3. Sunucu Bağımlılıklarının Kurulması (`install_dependencies.sh`)

Projede bulut maliyetlerini minimumda tutmak adına `t3.small` (2GB RAM) seçilmiştir. Sunucunun Minikube, Docker ve Helm'i kaldırabilmesi için hazırlanan otomasyon scriptini çalıştırın:

```bash
# Script'e çalıştırma izni verin
chmod +x install_dependencies.sh

# Altyapı kurulum zincirini başlatın (SWAP, Docker, Minikube, Helm, Kubectl)
./install_dependencies.sh
```

> 🚨 **Kritik Linux Notu (Oturum Yenileme):** Script içerisindeki `usermod` komutuyla kullanıcınız Docker grubuna dahil edilmiştir. Bu grup değişikliğinin sunucuda anında aktif olması ve sonraki adımlarda `Permission Denied` hatası almamak için şu komutla terminal oturumunuzu yenileyin:
>
> ```bash
> newgrp docker
> ```

---

## ☸️ Adım 4: Kubernetes (Minikube) & Helm ile Dağıtım

Sunucumuz `install_dependencies.sh` ile bir Kubernetes cluster'ına dönüştükten sonra, uygulamamızı network bağımlılıklarından uzak tutarak doğrudan **Minikube İç Mekanizması (Local Registry Injection)** ile ayağa kaldırıyoruz.

### 1. Dosya Konfigürasyonlarının Kontrolü

Sistem, `values-dev.yaml` üzerinden `image.pullPolicy: Never` olarak yapılandırılmıştır. Bu sayede Kubernetes internete gitmez, birazdan sunucu içinde build edeceğimiz imajı yakalar.

### 2. Tek Komutla Otomatik Dağıtım (`deploy.sh`)

Manuel olarak imaj build etme, terminali Minikube'a bağlama ve Helm yükleme adımlarının tamamını otomatize eden scripti çalıştırın:

```bash
# Script'e çalıştırma izni verin
chmod +x deploy.sh

# Otomasyon zincirini başlatın
./deploy.sh
```

### 3. Kurulumun Doğrulanması

Dağıtım otomasyonu bittikten sonra pod'un sağlık kontrollerini (Liveness/Readiness Probe) geçerek ayağa kalktığını doğrulayın:

```bash
kubectl get pods
```

`STATUS: Running` ve `READY: 1/1` çıktısını gördüğünüzde uygulamanız AWS üzerindeki Kubernetes kümesinde başarıyla canlıya alınmış demektir! 🎉

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