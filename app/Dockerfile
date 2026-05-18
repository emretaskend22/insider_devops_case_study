# --- Stage 1: Build Stage ---
FROM python:3.11-slim AS builder

WORKDIR /app

RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# --- Stage 2: Final Run Stage ---
FROM python:3.11-slim

# 1.2: Debian/Slim uyumlu root olmayan kullanıcı ve grup oluştur kanka
RUN groupadd -r appgroup && useradd -r -g appgroup appuser

WORKDIR /app

# 1.2: Sadece gerekli paketleri builderdan al
COPY --from=builder /opt/venv /opt/venv
COPY main.py .

ENV PATH="/opt/venv/bin:$PATH"

# Klasör yetkilerini oluşturulan kullanıcıya ver
RUN chown -R appuser:appgroup /app

# 1.2: Root olmayan kullanıcıya geçiş
USER appuser

EXPOSE 8080

# 1.2: HEALTHCHECK 
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8080/healthz', timeout=3)" || exit 1

CMD ["python", "main.py"]