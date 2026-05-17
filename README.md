# Insider DevOps Case Study - End-to-End Delivery Documentation

Bu repo, Insider DevOps Case Study kapsamında geliştirilen Python tabanlı API uygulamasının, AWS bulut altyapısının (IaC), Kubernetes (Minikube) orkestrasyonunun ve izleme (Monitoring) sistemlerinin uçtan uca kurulum süreçlerini içerir.

Projede **Maliyet Bilinci (Cost-Awareness)**, **Yüksek Erişilebilirlik (High Availability)**, **Güvenlik (Security)** ve **Otomasyon (Automation)** prensipleri ana kılavuz olarak benimsenmiştir.

---

## 📈 Proje Yol Haritası (Milestones)

### 🔹 Milestone 1: Uygulama Geliştirme & Dockerization
* Python tabanlı, hafif ve performanslı bir API geliştirildi.
* Uygulamanın her ortamda tutarlı çalışması için optimize edilmiş bir `Dockerfile` mimarisi kuruldu.

### 🔹 Milestone 2: Bulut Altyapısı & IaC (Terraform)
* AWS üzerinde tamamen kodla (IaC) güvenli bir network ve sunucu altyapısı kuruldu.
* Hesap kısıtlamalarını aşmak ve sistemi çökmez kılmak için OS seviyesinde SWAP Memory mimarisi optimize edildi.

### 🔹 Milestone 3: Kubernetes Orkestrasyonu (Minikube)
* *(YAKINDA)* Uygulama ve MongoDB veritabanı Kubernetes manifestoları (YAML) ile cluster içerisine yedekli (Replica) olarak dağıtılacak.

### 🔹 Milestone 4: Gözlemlenebilirlik (Monitoring & Alerting)
* *(YAKINDA)* Prometheus ve Grafana entegrasyonu ile sistem sağlığı ve metrikleri canlı olarak izlenecek.

---

## 🛠️ Detaylı Aşama Analizleri & "Neden-Niçin" Günlüğü (ADR)

### 📌 AŞAMA 1: Uygulama Geliştirme & Dockerization

* **Uygulama Seçimi:** Projenin core (çekirdek) API katmanı için Python dilinin hafif, asenkron ve yüksek performanslı modern kütüphaneleri tercih edilmiştir. API, veritabanı olarak MongoDB ile entegre çalışacak şekilde tasarlanmıştır.
* **Dockerfile Stratejisi:** İmaj boyutunu minimumda tutmak, saldırı yüzeyini azaltmak (Security) ve build sürelerini optimize etmek adına `Dockerfile` içerisinde **Multi-Stage Build** veya **Slim-Image** taktiği kullanılmıştır. Sadece uygulamanın çalışması için gerekli olan runtime bağımlılıkları production imajına dahil edilmiştir.

### 📌 AŞAMA 2: Bulut Altyapısı & IaC (Terraform)

#### 1. Neden `t3.small` Instance Tipi Seçildi?
* **Problem:** Minikube/Kubernetes kontrol düzleminin (control plane) kararlı çalışabilmesi için en az 2 vCPU ve 2GB-4GB RAM gerekmektedir (`t3.medium`). Ancak kişisel/yeni AWS hesaplarındaki katı **Free Tier vCPU kota kısıtlamaları (On-Demand vCPU blocking)** nedeniyle `t3.medium` sunucu istekleri AWS API katmanında reddedilmiştir.
* **Çözüm:** Teslimat (delivery) odağını kaybetmemek ve AWS hesap limitlerine tam uyum sağlamak adına, hesaba tanımlı ve onaylı olan en optimum model **`t3.small` (2 vCPU, 2GB RAM)** seçilmiştir.

#### 2. Neden İşletim Sistemi Seviyesinde SWAP Memory Kuruldu?
* **Problem:** `t3.small` sunucusunun sağladığı 2GB fiziksel RAM, Minikube'un ayağa kalkması için sınırda bir değerdir. İlerleyen aşamalarda (Milestone 3 ve 4) sisteme eklenecek olan Uygulama Pod'ları, MongoDB, Prometheus ve Grafana araçları fiziksel RAM sınırını aşarak **OOMKilled (Out Of Memory)** hatalarına ve sunucunun tamamen kilitlenmesine yol açacaktı.
* **Çözüm:** Fiziksel RAM yetersizliğini aşmak için 20GB'lık `gp3` diskin 4GB'lık kısmı **SWAP (Sanal Bellek)** alanı olarak konfigüre edilmiştir. Bu sayece sunucu toplam belleği yapay olarak 6GB seviyesine çekilmiştir. Geçici kaynak patlamalarında (burst) sistemin çökmesi engellenmiş, **Fail-Safe** ve yüksek erişilebilir bir mikro-altyapı simüle edilmiştir. (Kubernetes v1.28+ standartlarına tam uyum sağlanmıştır).

#### 3. Neden Ağ Güvenliği (Security Group) Sıkılaştırıldı?
* **Problem:** Altyapının internete açık olması, kaba kuvvet (brute-force) saldırılarına ve port tarama risklerine zemin hazırlar.
* **Çözüm:** Güvenlik duvarında (Security Group) HTTP (80) trafiği tüm dünyaya açık bırakılırken; kritik ve hassas olan **SSH (22)** portu ile **Kubernetes NodePort (30000-32767)** aralığı, Terraform değişkenleri (`var.my_ip`) kullanılarak **sadece geliştiricinin anlık IP adresine (`/32`) kilitlenmiştir.**

#### 4. Otomasyon (Configuration as Code)
* Sunucu provizyon edildikten sonra içeride yapılan tüm operasyonel adımlar (SWAP aktivasyonu, Docker kurulumu, kullanıcı izinleri ve optimize edilmiş Minikube cluster başlangıcı) `terraform/scripts/install_dependencies.sh` dosyası altında scriptleştirilerek sistemin tekrar üretilebilir (reproducible) olması sağlanmıştır.

---

## 📁 Proje Klasör Yapısı

```text
├── .gitignore
├── README.md
├── app/                      # Python API Kaynak Kodları & Dockerfile
└── terraform/                # Altyapı Kodları (IaC)
    ├── main.tf               # Ana AWS kaynak tanımları (EC2, SG, EIP)
    ├── providers.tf          # AWS Provider ve Bölge ayarı
    ├── variables.tf          # Dinamik değişken tanımları
    ├── terraform.tfvars      # Git'e girmeyen kişisel IP/Değişken değerleri
    └── scripts/
        └── install_dependencies.sh  # Sunucu içi otomatik kurulum betiği