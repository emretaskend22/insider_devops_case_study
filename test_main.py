from fastapi.testclient import TestClient
from main import app

client = TestClient(app)

def test_ping_endpoint():
    response = client.get("/ping")
    assert response.status_code == 200
    assert response.text == "pong"

def test_healthz_endpoint():
    response = client.get("/healthz")
    assert response.status_code == 200
    assert response.json() == {"status": "healthy"}

test_ping_endpoint()