import json
import logging
import sys
from app.config import settings

class JsonFormatter(logging.Formatter):
    def format(self, record):
        log_obj = {
            "timestamp": self.formatTime(record, "%Y-%m-%d %H:%M:%S"),
            "level": record.levelname,
            "msg": record.getMessage(),
            "request_id": getattr(record, "request_id", "N/A")
        }
        return json.dumps(log_obj)

def setup_logging():
    # Log seviyesini .env'den dinamik alıyoruz
    numeric_level = getattr(logging, settings.LOG_LEVEL, logging.INFO)
    
    root_logger = logging.getLogger()
    root_logger.setLevel(numeric_level)
    
    stdout_handler = logging.StreamHandler(sys.stdout)
    stdout_handler.setFormatter(JsonFormatter())

    for handler in root_logger.handlers[:]:
        root_logger.removeHandler(handler)
    root_logger.addHandler(stdout_handler)

    for logger_name in ("uvicorn", "uvicorn.error", "uvicorn.access"):
        uvicorn_logger = logging.getLogger(logger_name)
        uvicorn_logger.handlers = []
        uvicorn_logger.propagate = True

# Logging sistemini başlat
setup_logging()
logger = logging.getLogger("insider-app")