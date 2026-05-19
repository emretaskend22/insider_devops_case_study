# --- Stage 1: Build Stage ---
FROM python:3.11-alpine AS builder

WORKDIR /app

RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

COPY app/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# --- Stage 2: Final Run Stage ---
FROM python:3.11-alpine

# Alpine uyumlu hafif root olmayan kullanıcı ve grup oluştur
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# 🚨 DEĞİŞİKLİK 1: Çalışma dizinini /app yerine /workspace yapıyoruz ki 
# mutlak 'app.' import yolları container içinde pürüzsüz çalışsın.
WORKDIR /workspace

# Sadece gerekli paketleri builderdan al
COPY --from=builder /opt/venv /opt/venv

COPY app/ ./app/

ENV PATH="/opt/venv/bin:$PATH"

# EXPLICIT PIP + METADATA TEMİZLİĞİ (Alpine Versiyonu)
RUN /opt/venv/bin/pip uninstall -y wheel jaraco.context jaraco.functools || true && \
    rm -rf /usr/local/lib/python3.11/site-packages/wheel* \
           /usr/local/lib/python3.11/site-packages/jaraco* \
           /opt/venv/lib/python3.11/site-packages/wheel* \
           /opt/venv/lib/python3.11/site-packages/jaraco* \
           /opt/venv/bin/wheel

# Klasör yetkilerini oluşturulan kullanıcıya ver
RUN chown -R appuser:appgroup /workspace

# Root olmayan kullanıcıya geçiş
USER appuser

EXPOSE 8080

# HEALTHCHECK (FastAPI'de yeni '/healthz' endpoint'i veya ana sayfa kontrolü için uyarlandı)
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget -q --tries=1 --spider http://localhost:8080/healthz || exit 1

# 🚨 DEĞİŞİKLİK 3: Uygulamayı kök dizinden 'python -m app.main' olarak tetikliyoruz.
# Böylece Python 'app' paketini şak diye bulacak ve 'CrashLoopBackOff' hatası tarih olacak!
CMD ["python", "-m", "app.main"]