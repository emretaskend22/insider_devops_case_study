# --- Stage 1: Build Stage ---
FROM python:3.11-alpine AS builder

WORKDIR /app

RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

COPY app/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# --- Stage 2: Final Run Stage ---
FROM python:3.11-alpine

RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /workspace


COPY --from=builder /opt/venv /opt/venv

COPY app/ ./app/

ENV PATH="/opt/venv/bin:$PATH"


RUN /opt/venv/bin/pip uninstall -y wheel jaraco.context jaraco.functools || true && \
    rm -rf /usr/local/lib/python3.11/site-packages/wheel* \
           /usr/local/lib/python3.11/site-packages/jaraco* \
           /opt/venv/lib/python3.11/site-packages/wheel* \
           /opt/venv/lib/python3.11/site-packages/jaraco* \
           /opt/venv/bin/wheel


RUN chown -R appuser:appgroup /workspace

# Root olmayan kullanıcıya geçiş
USER appuser

EXPOSE 8080

# HEALTHCHECK (FastAPI'de yeni '/healthz' endpoint'i veya ana sayfa kontrolü için uyarlandı)
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget -q --tries=1 --spider http://localhost:8080/healthz || exit 1


CMD ["python", "-m", "app.main"]