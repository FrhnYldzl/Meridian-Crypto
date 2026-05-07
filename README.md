# Meridian Capital — Crypto V6.0

Standalone crypto trading module. Lives in its own GitHub repo and Railway project — no shared code with other asset classes.

- **Asset class:** Crypto (Alpaca paper)
- **Universe:** Core 10 + Extended 33 (stablecoins excluded)
- **Brain:** Claude Sonnet 4.5 + ephemeral prompt caching
- **Auditor:** Gemini Flash-Lite second opinion (optional)
- **Dashboard:** Bloomberg-grade, BTC orange (`#f7931a`)

## Layout

```
meridian-crypto-v6/
├── Dockerfile             # CMD: uvicorn crypto_preview_app:app
├── railway.json           # Railway: DOCKERFILE builder, healthcheck /api/crypto/health
├── requirements.txt
├── .env.example
├── .gitignore
└── server/
    ├── crypto_preview_app.py   # FastAPI entry — 24 /api/crypto/* endpoints
    ├── config.py
    ├── risk_manager.py         # Legacy V5.7 risk engine (wrapped by crypto/risk_impl)
    ├── core/                   # Abstract bases (Brain/Broker/Regime/Risk/Scheduler)
    ├── crypto/                 # Crypto implementation (13 files, ~3.9k LOC)
    │   ├── universe.py         # Core 10 + Extended 33
    │   ├── data.py             # Alpaca crypto OHLCV + indicators
    │   ├── broker_impl.py      # Manual bracket threading
    │   ├── regime_impl.py      # BTC-benchmark 4-component regime
    │   ├── risk_impl.py        # 1% risk, 2× ATR, asset-group caps (DeFi/L1/Meme/…)
    │   ├── scheduler_impl.py   # 24/7 — is_active_session always True
    │   ├── brain_impl.py       # CryptoBrain (Sonnet 4.5 + caching)
    │   ├── audit_impl.py       # Gemini council
    │   ├── auto_executor.py    # Pipeline + safety gates (no PDT)
    │   ├── journal.py          # SQLite seyir defteri (Volume-mounted)
    │   ├── news_impl.py        # CryptoCompare news + sentiment
    │   └── anomaly_impl.py     # Flash dump / vol spike detection
    ├── static/crypto/index.html
    └── data/                   # Journal SQLite (gitignored except .gitkeep)
```

## Local dev

```bash
pip install -r requirements.txt
cp .env.example .env       # then fill keys
cd server
uvicorn crypto_preview_app:app --host 127.0.0.1 --port 8010 --reload
```

Dashboard: http://127.0.0.1:8010/  
Health:    http://127.0.0.1:8010/api/crypto/health

The Claude Code preview is wired to the server name **"Meridian Crypto V6.0"** in the parent `.claude/launch.json` (port 8010).

## Endpoint catalog (24)

```
/api/crypto/health           /api/crypto/audit
/api/crypto/universe         /api/crypto/anomalies
/api/crypto/account          /api/crypto/news
/api/crypto/market-data      /api/crypto/regime
/api/crypto/positions        /api/crypto/orders
/api/crypto/scheduler        /api/crypto/scheduler-status
/api/crypto/brain            /api/crypto/run-now
/api/crypto/risk-config      /api/crypto/env-debug
/api/crypto/extended-data    /api/crypto/overview-charts
/api/crypto/bars/{symbol}    /api/crypto/symbol-summary/{symbol}
/api/crypto/journal                    (recent)
/api/crypto/journal/performance        (aggregate)
/api/crypto/journal/run/{run_id}       (timeline)
/api/crypto/journal/open-trades
```

Plus `/`, `/static/*`, `/api/modules`.

## GitHub setup

```bash
cd meridian-crypto-v6
git init
git add -A
git commit -m "Meridian Crypto V6.0 — initial commit (split from trading-agent-v58)"

# Create empty repo on github.com/<your-handle>/meridian-crypto first, then:
git branch -M main
git remote add origin https://github.com/<your-handle>/meridian-crypto.git
git push -u origin main
```

## Railway setup (new project)

1. **New Project → Deploy from GitHub** → pick the `meridian-crypto` repo, branch `main`.
2. **Settings → Build:** Builder `Dockerfile`, path `Dockerfile` (the only one in the repo).
3. **Settings → Networking:** generate domain, optionally CNAME `crypto.meridian.app`.
4. **Settings → Volumes:** mount `/app/data` (journal SQLite persists across deploys).
5. **Variables (paste from `.env.example`, then fill):**
   ```
   CRYPTO_ALPACA_API_KEY=PK...
   CRYPTO_ALPACA_SECRET_KEY=...
   CRYPTO_ALPACA_PAPER=true
   CRYPTO_ACCOUNT_LABEL=Ferhan Crypto Paper #1
   ANTHROPIC_API_KEY=sk-ant-...
   CRYPTO_BRAIN_MODEL=claude-sonnet-4-5-20250929
   GEMINI_API_KEY=                   # optional
   CRYPTO_AUTO_EXECUTE=false         # flip to true only after smoke test
   CRYPTO_DRY_RUN=true               # flip to false to send real paper orders
   JOURNAL_DB_PATH=/app/data/crypto_journal.db
   ```
6. **Deploy Latest** — wait for build, then verify `/api/crypto/health` returns 200.

## Safety defaults

- `CRYPTO_DRY_RUN=true` — broker logs orders but does not submit
- `CRYPTO_AUTO_EXECUTE=false` — scheduler does not auto-fire pipeline
- `paper=true` hard-coded in broker constructor
- Max 1% risk per trade, 40% per asset group, flash-crash halt at –5% in 5min

Toggle these only after the dashboard, journal, and brain endpoints have been observed cleanly for at least one full session.

## Source attribution

Initial code lifted from `trading-agent-v58` branch `claude/v5.8-abstract-bases` (commit `f3b73e9` baseline) and stripped to crypto-only. The original V5.10 production at the `devine-laughter` Railway project is not touched by this repo.
