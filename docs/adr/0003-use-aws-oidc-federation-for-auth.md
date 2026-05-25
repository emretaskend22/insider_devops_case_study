# ADR-0003: CI/CD Süreçlerinde AWS Kimlik Doğrulaması İçin OIDC Federation Kullanımı

## Durum (Status)
Kabul Edildi

## Bağlam (Context)
Sürekli Entegrasyon (CI) pipeline'ımızın, dağıtım öncesinde AWS EC2 Security Group kurallarını dinamik olarak güncellemesi (GitHub Runner IP'sine geçici izin vermesi) gerekmektedir. Bu işlemi otomatize etmek için GitHub Actions'ın AWS kaynaklarıyla konuşabilmesi şarttır. Geleneksel yöntem, AWS üzerinden uzun ömürlü bir IAM Kullanıcısı oluşturup, buna ait statik `Access Key` ve `Secret Key` bilgilerini GitHub Secrets içinde saklamaktır. Ancak statik anahtarların kullanılması; anahtarların kod içine sızması, yetkisiz kişilerin eline geçmesi ve düzenli anahtar rotasyonunun yapılmaması gibi çok ciddi güvenlik zafiyetleri barındırmaktadır.

## Karar (Decision)
Projede "Sıfır Güven" (Zero-Trust) mimarisini benimseyerek, statik anahtar kullanımı yerine AWS ve GitHub Actions arasında **OIDC (OpenID Connect) Federation** kurmaya karar verdik.

Altyapı (IaC) tarafında bir AWS IAM Role ve Identity Provider (Kimlik Sağlayıcı) tanımlanmıştır. GitHub Actions pipeline'ı çalıştığında, `aws-actions/configure-aws-credentials` aksiyonunu kullanarak AWS'den sadece o anlık geçerli olan, kısa ömürlü ve geçici bir kimlik doğrulama token'ı talep eder. AWS, bu token'ı yalnızca bizim repository'mizden gelen isteklere (Trust Relationship) istinaden verir.

## Sonuçlar (Consequences)
* **(+) Sıfır Kalıcı Anahtar (Zero-Trust):** Kod reposu, pipeline dosyaları veya GitHub Secrets içerisinde çalınabilecek hiçbir uzun ömürlü AWS kimlik bilgisi (credential) barındırılmaz.
* **(+) Operasyonel Kolaylık:** Statik anahtarların periyodik olarak değiştirilmesi (key rotation) yükü tamamen ortadan kalkmıştır.
* **(+) Katı Yetkilendirme:** Tanımlanan IAM Rolü, yalnızca belirli bir GitHub reposu ve branch'i tarafından üstlenilebilecek şekilde kısıtlanarak erişim yetkisi en aza indirilmiştir (Least Privilege).
* **(-) Artan Karmaşıklık:** OIDC Federation ve IAM Trust Policy kurulumları, basit bir IAM kullanıcısı oluşturup anahtar üretmeye kıyasla Terraform (IaC) tarafında daha karmaşık bir başlangıç eforu gerektirmiştir.