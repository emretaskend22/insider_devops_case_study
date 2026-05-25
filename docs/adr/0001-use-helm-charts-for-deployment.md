# ADR-0001: Kubernetes Dağıtımı ve Konfigürasyon Yönetimi İçin Helm Chart Kullanımı

## Durum (Status)
Kabul Edildi

## Bağlam (Context)
Birden fazla uygulama ortamı için ham Kubernetes manifestolarını (`deployment.yaml`, `service.yaml`, `ingress.yaml`) yönetmek; ciddi bir bakım yükü, konfigürasyon kodu tekrarı ve konfigürasyon sapması (configuration drift) riski doğurur. Bu case study için, durumsuz (stateless) Python FastAPI uygulamasının iki farklı ortamda dağıtılması gerekmektedir: hafif ve maliyet odaklı bir Geliştirme (Development) ortamı ile AWS `t3.small` sunucusunda koşan, yüksek erişilebilirliğe (HA) sahip ve sıkı izlenen bir Canlı (Production) ortam. Ham ve statik manifestolar kullanmak; ortama özgü konfigürasyonları (replika sayıları, yatay ölçeklendirme kuralları, kaynak limitleri ve izleme parametreleri gibi) yönetmeyi son derece hataya açık hale getirecektir.

## Karar (Decision)
Tüm Kubernetes altyapısını ve uygulama dağıtımlarını yönetmek için temel paket yöneticisi ve şablon motoru olarak Helm'i benimsemeye karar verdik. 

Statik YAML manifestoları yazmak yerine, `insider-app` adında birleştirilmiş ve parametrik bir Helm chart oluşturduk. Ortam ayrımı, özel değerler (values) dosyaları kullanılarak konfigürasyon seviyesinde katı bir şekilde sağlanmıştır:
* `values-dev.yaml`: Test ortamında maliyetleri optimize etmek için tek bir pod replikası, kesin lokal imaj çekme stratejisi (`pullPolicy: Never`) ve minimum düzeyde kaynak tahsisleriyle yapılandırılmıştır.
* `values-prod.yaml`: Yüksek erişilebilirlik (minimum 3 replika), kararlı yatay ölçeklendirme (`t3.small` kısıtlarına uygun olarak 5 replikaya kadar HPA), daha yüksek dikey kaynak sınırları ve cluster metriklerini toplamak için aktif bir Prometheus `ServiceMonitor` içerecek şekilde yapılandırılmıştır.

## Sonuçlar (Consequences)
* **(+) DRY Prensibine Uyum (Don't Repeat Yourself):** Tek bir Helm chart'ı temel mimari şablonunu tanımlar ve Kubernetes kaynak bildirimlerindeki kod tekrarını tamamen ortadan kaldırır.
* **(+) Atomik Güncellemeler ve Geri Dönüşler (Rollbacks):** Dağıtımlar atomik işlemlerle (`helm upgrade --install`) gerçekleştirilir. Canlıya alım sırasında bir hata oluşursa, cluster durumu `helm rollback` kullanılarak anında ve güvenli bir şekilde eski haline döndürülebilir.
* **(+) Konfigürasyon Esnekliği:** Ortama özgü ayarlar, temel altyapı kodundan tamamen ayrıştırılmış olup, hızlı ve risksiz konfigürasyon değişikliklerine olanak tanır.
* **(-) Artan Karmaşıklık:** Helm sözdizimi soyutlaması (syntax abstraction) ve iç içe geçmiş şablon bağımlılıkları getirir; bu da ekibin saf Kubernetes manifestoları yerine Helm chart yapılarını öğrenmesini ve anlamasını gerektirir.