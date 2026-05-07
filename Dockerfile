# ════════════════════════════════════════════════════════════════════
# Dockerfile — Meridian Capital · Crypto Module (V6.0)
# Standalone repo: only the crypto stack, no equity bleed.
# ════════════════════════════════════════════════════════════════════

FROM python:3.12-slim

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY server/ ./server/

# Persistent journal (mount Railway Volume here in prod)
RUN mkdir -p /app/data
ENV JOURNAL_DB_PATH=/app/data/crypto_journal.db

ENV PYTHONPATH=/app/server
ENV PORT=8000
EXPOSE 8000

WORKDIR /app/server

CMD ["sh", "-c", "exec uvicorn crypto_preview_app:app --host 0.0.0.0 --port ${PORT:-8000}"]
