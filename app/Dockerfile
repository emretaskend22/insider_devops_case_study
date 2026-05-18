# --- Stage 1: Build Stage ---
FROM python:3.11-slim AS builder

WORKDIR /app

RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# --- Stage 2: Final Run Stage ---
FROM python:3.11-slim

# 1.2: Debian/Slim uyumlu root olmayan kullanıcı ve grup oluştur
RUN groupadd -r appgroup && useradd -r -g appgroup appuser

WORKDIR /app

# 🌟 DOKUNUŞ 1 (OS Hardening): İşletim sistemi paketlerini güncelle ve açıkları kapat!
# Ardından imaj boyutu şişmesin diye apt önbelleğini temizliyoruz kanka.
RUN apt-get update && \
    apt-get upgrade -y && \
    rm -rf /var/lib/apt/lists/*

# 1.2: Sadece gerekli paketleri builderdan al
COPY --from=builder /opt/venv /opt/venv
COPY main.py .

ENV PATH="/opt/venv/bin:$PATH"

# 🌟 DOKUNUŞ 2 (Python Hardening): İmajdaki hazır gelen açık kaynaklı kalıntıları tamamen uçur!
RUN pip uninstall -y wheel jaraco.context

# Klasör yetkilerini oluşturulan kullanıcıya ver
RUN chown -R appuser:appgroup /app

# 1.2: Root olmayan kullanıcıya geçiş
USER appuser

EXPOSE 8080

# 1.2: HEALTHCHECK 
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8080/healthz', timeout=3)" || exit 1

CMD ["python", "main.py"]