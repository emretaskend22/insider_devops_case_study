import os
from fastapi import FastAPI, Response

app = FastAPI()

# 1.1: GET /ping -> pong
@app.get("/ping", response_class=Response)
def ping():
    return Response(content="pong", media_type="text/plain")

# 1.1: GET /healthz -> Probes için
@app.get("/healthz")
def healthz():
    return {"status": "healthy"}

# 1.1: GET /version -> Build SHA bilgisi
@app.get("/version")
def version():
    build_sha = os.getenv("BUILD_SHA", "local-development")
    return {"build_sha": build_sha}

if __name__ == "__main__":
    import uvicorn
    port = int(os.getenv("APP_PORT", 8080))
    uvicorn.run(app, host="0.0.0.0", port=port)