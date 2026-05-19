import os

class Config:
    APP_PORT: int = int(os.getenv("APP_PORT", 8080))
    LOG_LEVEL: str = os.getenv("LOG_LEVEL", "INFO").upper()
    BUILD_SHA: str = os.getenv("BUILD_SHA", "local-development")

settings = Config()