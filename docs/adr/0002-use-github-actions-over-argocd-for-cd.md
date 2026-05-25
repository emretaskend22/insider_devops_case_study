# ADR-0002: Sürekli Dağıtım (CD) İçin ArgoCD (GitOps) Yerine GitHub Actions Kullanımı

## Durum (Status)
Kabul Edildi

## Bağlam (Context)
Projenin "Sürekli Dağıtım (Continuous Deployment)" aşamasında, `main` branch'ine yapılan kod birleştirmelerinin (merge) ardından uygulamanın otomatik olarak Kubernetes kümesine (Minikube) dağıtılması gerekmektedir. Güncel endüstri standartları, bu işlem için ArgoCD veya Flux gibi "Pull-based" (Çekme tabanlı) GitOps araçlarını önermektedir. Ancak projemizin çalıştığı altyapı, oldukça kısıtlı donanım kaynaklarına sahip olan bir AWS `t3.small` (2 vCPU, 2GB RAM) sunucusudur. Bu sunucu halihazırda Minikube, FastAPI uygulaması, Prometheus, Grafana ve diğer metrik araçlarını barındırmaktadır. Kümeye ArgoCD gibi sürekli arka planda çalışan ve Git reposunu dinleyen bir araç kurmak, ciddi bir bellek (RAM) ve CPU tüketimi yaratarak uygulamanın kararlılığını (stability) tehlikeye atacaktır.

## Karar (Decision)
GitOps araçlarının sunduğu avantajların farkında olmakla birlikte, mevcut donanım kısıtları nedeniyle dağıtım sürecini ArgoCD yerine "Push-based" (İtme tabanlı) olan **GitHub Actions** üzerinden yönetmeye karar verdik.

Pipeline tetiklendiğinde; imajın derlenmesi, Trivy ile taranması ve GHCR'a yüklenmesi işlemleri tamamen GitHub sunucularında gerçekleşir. Dağıtım aşamasında ise runner, kümemize (EC2) SSH üzerinden güvenli bir şekilde bağlanarak `helm upgrade` komutunu doğrudan çalıştırır.

## Sonuçlar (Consequences)
* **(+) Kaynak Verimliliği:** Hedef EC2 sunucusunda gereksiz RAM ve CPU tüketiminin önüne geçilmiş, kısıtlı kaynaklar tamamen canlı uygulamanın ve izleme (monitoring) araçlarının sağlığına ayrılmıştır.
* **(+) Tekil Akış Yönetimi:** Sürekli Entegrasyon (CI) ve Sürekli Dağıtım (CD) süreçleri tek bir `.yaml` dosyası üzerinden uçtan uca izlenebilir hale gelmiştir.
* **(-) Güvenlik Ödünü (Trade-off):** Push-based bir yaklaşım olduğu için sunucunun (EC2) geçici de olsa dışarıdan bir bağlantıya açılması gerekmiştir. Bu risk, AWS Security Group üzerinden dinamik IP beyaz listeye alma (whitelisting) adımıyla hafifletilmiştir.
* **(-) Konfigürasyon Sapması (Drift Detection) Eksikliği:** ArgoCD'nin aksine, küme içerisinde manuel bir değişiklik yapıldığında sistem bunu otomatik olarak algılayıp Git reposundaki haline zorla eşitlemeyecektir (self-healing gitops).