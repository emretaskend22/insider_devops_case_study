from fastapi import FastAPI, Response
from prometheus_client import generate_latest, CONTENT_TYPE_LATEST
from app.config import settings
from app.middleware import observability_middleware

app = FastAPI()

# Gözetlenebilirlik middleware'ini bağlıyoruz
app.middleware("http")(observability_middleware)

@app.get("/metrics")
def metrics():
    return Response(content=generate_latest(), media_type=CONTENT_TYPE_LATEST)

@app.get("/ping", response_class=Response)
def ping():
    return Response(content="pong", media_type="text/plain")

@app.get("/healthz")
def healthz():
    return {"status": "healthy"}

@app.get("/version")
def version():
    return {"build_sha": settings.BUILD_SHA}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("app.main:app", host="0.0.0.0", port=settings.APP_PORT, reload=True)