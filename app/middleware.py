import time
import uuid
from fastapi import Request, Response
from app.logger import logger
from app.metrics import HTTP_REQUESTS_TOTAL, HTTP_REQUEST_DURATION_SECONDS

async def observability_middleware(request: Request, call_next):
    start_time = time.time()
    request_id = request.headers.get("X-Request-ID", str(uuid.uuid4()))
    extra_args = {"request_id": request_id}
    
    response: Response = await call_next(request)
    duration = time.time() - start_time
    
    if request.url.path != "/metrics":
        HTTP_REQUESTS_TOTAL.labels(
            method=request.method, 
            endpoint=request.url.path, 
            status_code=response.status_code
        ).inc()
        
        HTTP_REQUEST_DURATION_SECONDS.labels(
            method=request.method, 
            endpoint=request.url.path
        ).observe(duration)
        
        logger.info(
            f"Processed {request.method} {request.url.path} - Status: {response.status_code} - Duration: {duration:.4f}s",
            extra=extra_args
        )
    
    response.headers["X-Request-ID"] = request_id
    return response