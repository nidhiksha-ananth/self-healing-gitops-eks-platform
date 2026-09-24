from flask import Flask, jsonify, request
import uuid

app = Flask(__name__)

# In-memory store — fine for a demo/portfolio app.
# A real production version would use a database (RDS, DynamoDB, etc.)
tasks = {}


@app.route("/health")
def health():
    """
    Used by Kubernetes readiness/liveness probes later (Day 4).
    Keep this fast and dependency-free so probes are reliable.
    """
    return jsonify(status="ok"), 200


@app.route("/")
def index():
    return jsonify(message="Task API is running"), 200


@app.route("/tasks", methods=["GET"])
def list_tasks():
    return jsonify(list(tasks.values())), 200


@app.route("/tasks", methods=["POST"])
def create_task():
    data = request.get_json(silent=True) or {}
    title = data.get("title")
    if not title:
        return jsonify(error="title is required"), 400

    task_id = str(uuid.uuid4())
    task = {"id": task_id, "title": title, "done": False}
    tasks[task_id] = task
    return jsonify(task), 201


@app.route("/tasks/<task_id>", methods=["DELETE"])
def delete_task(task_id):
    if task_id not in tasks:
        return jsonify(error="not found"), 404
    del tasks[task_id]
    return "", 204


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
