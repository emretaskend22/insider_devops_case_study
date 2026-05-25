# 📖 RUNBOOK: Olay Müdahale ve Operasyon Kılavuzu

Bu döküman, **Insider DevOps Case Study** projesinin production ortamında meydana gelebilecek olası arıza, alarm ve kesinti durumlarında uygulanacak operasyonel müdahale adımlarını (Incident Response) içerir.

---

# 📌 1. Temel Sistem Durumu Kontrolü (Health Check)

Sistemde beklenmeyen davranışlar gözlemlendiğinde veya bir alarm tetiklendiğinde ilk çalıştırılması gereken temel kontrol komutları aşağıdadır.

---

## Kubernetes Pod Durumları

Uygulama pod'larının durumunu, restart sayılarını ve yaşlarını kontrol edin:

```bash
kubectl get pods -n insider-app
```

### ✅ Normal Durum

- Tüm pod'ların `STATUS` değeri `Running`
- `READY` değeri `1/1`
- Restart sayısı stabil olmalıdır

### 🚨 Kritik Durum

Aşağıdaki durumlar acil müdahale gerektirir:

- `CrashLoopBackOff`
- `ImagePullBackOff`
- `Pending`
- Sürekli artan restart sayısı

---

## Helm Dağıtım Durumu

Mevcut canlı sürümü (revision) ve son deployment zamanını görüntüleyin:

```bash
helm list -n insider-app
```

---

# 🚨 2. Yaygın Hata Senaryoları ve Müdahale Adımları

---

## 🟥 Senaryo A: Grafana HighErrorRate Alarmı (%5+ 5xx Hatası)

Grafana veya Prometheus üzerinden uygulamanın yüksek oranda `5xx` hata kodu döndürdüğüne dair alarm alındığında:

### 1. Uygulama Loglarını İnceleyin

Pod loglarını canlı olarak takip edin:

```bash
kubectl logs -l app.kubernetes.io/name=insider-app -n insider-app --tail=100 -f
```

Loglar üzerinden aşağıdaki durumları araştırın:

- Python exception'ları
- Timeout problemleri
- External service bağlantı hataları
- Resource exhaustion (CPU/RAM)
- Database connection problemleri

---

### 2. `request_id` ile Hatalı İstekleri Takip Edin

JSON log yapısındaki `request_id` alanını kullanarak:

- Problemli endpoint'i
- Hatanın tekrar üretilebilir olup olmadığını
- Aynı isteğin sistem içindeki izini

tespit edin.

---

## 🟨 Senaryo B: Deployment Sırasında `ImagePullBackOff`

Yeni bir sürüm dağıtılırken pod'ların container imajını çekememesi durumunda:

### 1. Rollout Durumunu Kontrol Edin

```bash
kubectl rollout status deployment/insider-dev-insider-app -n insider-app
```

---

### 2. Sistemin Korunduğunu Doğrulayın

Kubernetes aşağıdaki mekanizmalar sayesinde sistemi korur:

- Rolling Update strategy
- Readiness Probe
- ReplicaSet failover mekanizması

Yeni pod'lar sağlıklı hale gelmediği sürece eski stabil pod'lar trafiği karşılamaya devam eder.

Bu sayede deployment sırasında downtime yaşanmaz.

---

# 🔄 3. Felaket Kurtarma (Rollback)

Yeni sürüm:

- sistemi kilitliyorsa,
- memory leak oluşturuyorsa,
- kritik performans problemi yaratıyorsa,
- çözülemeyen production hatalarına sebep oluyorsa

önceki stabil sürüme derhal rollback yapılmalıdır.

---

## Sürüm Geçmişini Listeleyin

```bash
helm history insider-dev -n insider-app
```

Bu komut:

- aktif sürümü (`deployed`)
- eski sürümleri (`superseded`)
- başarısız rollout'ları

listeleyecektir.

---

## Son Stabil Sürüme Rollback Yapın

Örneğin:

- Hatalı sürüm: `Revision 7`
- Stabil sürüm: `Revision 6`

ise rollback işlemi:

```bash
helm rollback insider-dev 6 -n insider-app
```

---

## Rollback Sonrası Doğrulama

Pod'ların eski stabil imaja başarıyla döndüğünü izleyin:

```bash
kubectl get pods -n insider-app -w
```

Beklenen durum:

- Yeni pod'ların `Running` olması
- Restart döngüsünün sona ermesi
- Error rate metriklerinin normale dönmesi

---

# 📊 4. Yararlı Operasyonel Komutlar (Cheat Sheet)

---

## HPA (Horizontal Pod Autoscaler) Durumu

Ani trafik artışlarında pod sayısının nasıl ölçeklendiğini görmek için:

```bash
kubectl get hpa -n insider-app
```

---

## Pod Resource Kullanımı

CPU ve RAM tüketimini görüntülemek için:

```bash
kubectl top pods -n insider-app
```

---

## Deployment Detaylarını Görüntüleme

```bash
kubectl describe deployment insider-dev-insider-app -n insider-app
```

---

# 🛡️ Operasyonel Notlar

- Production ortamında manuel değişikliklerden kaçınılmalıdır.
- Altyapı değişiklikleri yalnızca Terraform üzerinden uygulanmalıdır.
- Kubernetes manifest değişiklikleri Helm chart üzerinden yönetilmelidir.
- Tüm deployment süreçleri CI/CD pipeline üzerinden ilerlemelidir.
- Kritik production müdahaleleri sonrasında incident review yapılması önerilir.

---