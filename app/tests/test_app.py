import sys
import os

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from app import app


def test_health():
    client = app.test_client()
    resp = client.get("/health")
    assert resp.status_code == 200
    assert resp.get_json()["status"] == "ok"


def test_index():
    client = app.test_client()
    resp = client.get("/")
    assert resp.status_code == 200


def test_create_and_list_task():
    client = app.test_client()
    resp = client.post("/tasks", json={"title": "Learn Terraform"})
    assert resp.status_code == 201
    task = resp.get_json()
    assert task["title"] == "Learn Terraform"

    resp = client.get("/tasks")
    assert resp.status_code == 200
    assert any(t["title"] == "Learn Terraform" for t in resp.get_json())


def test_create_task_missing_title():
    client = app.test_client()
    resp = client.post("/tasks", json={})
    assert resp.status_code == 400
