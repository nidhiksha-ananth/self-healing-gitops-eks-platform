# Small base image — fewer packages means fewer vulnerabilities for Trivy
# to flag and a smaller image to push/pull.
FROM python:3.12-slim

WORKDIR /app

# Install dependencies first, separately from app code.
# Docker caches layers — this way, changing app.py doesn't force a full
# pip reinstall every build, only changing requirements.txt does.
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .

# Security practice (called out in the project spec): don't run containers
# as root. Create a dedicated non-root user and switch to it.
RUN useradd --create-home --shell /bin/bash appuser
USER appuser

EXPOSE 5000

# Kubernetes will do its own health checks later (Day 4), but this
# Docker-level HEALTHCHECK is still good practice for running the
# container standalone (e.g. `docker run`) or in tools that respect it.
HEALTHCHECK --interval=30s --timeout=3s \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:5000/health')" || exit 1

# gunicorn instead of Flask's dev server — dev server isn't meant for
# anything beyond local debugging.
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "2", "app:app"]
