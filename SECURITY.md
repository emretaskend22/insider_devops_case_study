# Security Policy (Güvenlik Politikası)

Bu döküman, **Insider DevOps Case Study** projesinin güvenlik mimarisini, DevSecOps süreçlerini ve olası güvenlik zafiyetlerinin nasıl ele alınacağını tanımlar.

## 🔒 Güvenlik Mimarisi ve DevSecOps Katmanları

Proje baştan aşağı "Sıfır Güven" (Zero-Trust) ve "En Az Ayrıcalık" (Least Privilege) prensipleri üzerine inşa edilmiştir. Sistemde uygulanan aktif güvenlik önlemleri şunlardır:

* **Sırların Korunması (Secret Scanning):**
  GitHub Actions pipeline'ımızda `gitleaks` entegrasyonu bulunmaktadır. Koda yanlışlıkla API anahtarı, token veya herhangi bir şifre gömülürse, pipeline anında kırılır ve kodun pushlanması engellenir.
* **Şifresiz Kimlik Doğrulama (OIDC Federation):**
  AWS ile iletişim kurmak için repoda hiçbir statik IAM AWS anahtarı barındırılmaz. Bunun yerine **AWS OIDC Federation** kullanılarak, pipeline anında geçici ve kısa ömürlü token'lar üzerinden güvenli el sıkışma sağlanır.
* **Konteyner ve İmaj Güvenliği:**
  GHCR'a basılmadan önce tüm Docker imajları **Trivy** ile zafiyet taramasından geçirilir. `CRITICAL` veya `HIGH` seviyeli bir zafiyet bulunursa sistem imajı reddeder.
* **Tedarik Zinciri Güvenliği (SBOM):**
  Uygulamanın şeffaflığı için her derleme (build) sonrasında **Syft** ile yazılım bileşenleri envanteri (SBOM) oluşturulur ve arşivlenir.
* **Dinamik Ağ Güvenliği (Dynamic Firewall):**
  Uygulamanın koştuğu AWS EC2 sunucusunun SSH portu (22) dünyaya kapalıdır. CI/CD dağıtımı sırasında, Terraform altyapısı üzerinden GitHub Runner'ın IP adresine sadece saniyeler süren geçici bir geçiş izni verilir ve işlem bitince bu yetki otomatik olarak geri alınır.

## 🛠️ Desteklenen Sürümler

Şu anda sadece en güncel kararlı sürüm aktif olarak güvenlik güncellemeleri almaktadır:

| Versiyon | Güvenlik Güncellemesi Durumu |
| :--- | :--- |
| `v0.1.x` | ✅ Aktif olarak destekleniyor |
| `< v0.1.0` | ❌ Desteklenmiyor |

## 🚨 Zafiyet Bildirimi (Vulnerability Reporting)

Sistemde bir güvenlik açığı veya kritik bir sızıntı tespit ederseniz, lütfen bunu public issue'lar (açık kayıtlar) üzerinden paylaşmak yerine doğrudan proje yöneticisi ile iletişime geçerek bildiriniz. 

Kabul edilen bir zafiyet bildirimi sonrasında:
1. Bildirim onaylanır ve süreç başlatılır.
2. Sorunun kök nedeni analiz edilerek bir yama (patch) geliştirilir.
3. Düzeltilmiş sürüm, yeni bir SemVer etiketi (örneğin `v0.1.1`) ile duyurulur.