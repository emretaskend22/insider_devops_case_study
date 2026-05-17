# --- Stage 1: Build Stage ---
FROM python:3.11-alpine AS builder

WORKDIR /app

RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# --- Stage 2: Final Run Stage ---
FROM python:3.11-alpine

# 1.2: none root kullanıcı ve grup oluştur
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app

# 1.2: Sadece gerekli paketleri builderdan al (multi-stage)
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
  CMD wget -q --tries=1 --spider http://localhost:8080/healthz || exit 1

CMD ["python", "main.py"]