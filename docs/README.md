# Baseera
### AISeekho 2026 Google Antigravity Hackathon — Challenge 1: Autonomous Content-to-Action Agent

---

## Project Overview

**Baseera** is a production-ready autonomous business intelligence system built for the AISeekho 2026 Hackathon. It demonstrates how an AI agent can simultaneously ingest multiple conflicting data sources, detect contradictions using credibility reasoning, generate a prioritized action chain, and autonomously execute those actions — including recovering from failures without human intervention.

Scenario: a Lahore grocery chain faces a supply-chain crisis. Warehouse system shows 1,200 units of Basmati Rice 5kg, but customers flood support with "out of stock" errors, a supplier confirms a 5-day delivery delay due to a Punjab transport strike, and sales data shows the stock should have been depleted 3 days ago. Baseera detects the contradiction, identifies the stale warehouse data as the culprit, and autonomously executes a 4-step recovery plan.

**Tech Stack**: Flutter 3.x (Android) + Python 3.11 FastAPI + Gemini 2.5 Flash. Premium royal dark theme, Lucide icon set, Outfit typography.

---

## Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│                       Baseera Flutter App                          │
│                                                                    │
│  Splash → Home → Sources → Action Chain → Outcome                  │
│                                                                    │
│  State:    Provider (AnalysisProvider)                             │
│  HTTP:     Dio                                                      │
│  URL:      kDebugMode ? http://10.0.2.2:8000                       │
│                       : BASEERA_API_URL  (mobile/.env)             │
└────────────────────────────────┬──────────────────────────────────┘
                                 │ REST (JSON)
                                 ▼
┌──────────────────────────────────────────────────────────────────┐
│             FastAPI Backend (local :8000 OR cloud HTTPS)           │
│                                                                    │
│  POST /api/analyze        Load 5 sources + Gemini call             │
│  POST /api/execute-step   Step simulation (Step 2 fails+retries)   │
│  GET  /api/outcome        Before/after metrics                     │
│  GET  /api/health         Liveness + key status                    │
│                                                                    │
│  agents/data_loader.py       5 mock files                          │
│  agents/gemini_client.py     Gemini 2.5 Flash + fallback           │
│  agents/action_executor.py   In-memory step state machine          │
└────────────────────────────────┬──────────────────────────────────┘
                                 │
                                 ▼
                  Google Gemini 2.5 Flash API
```

For a deeper system diagram, state machines, and design patterns see [architecture.md](architecture.md).

---

## Running the Backend Locally

### Prerequisites
- Python 3.11+
- pip

### Steps

```powershell
cd backend
python -m venv venv
venv\Scripts\activate          # PowerShell on Windows
pip install -r requirements.txt
Copy-Item .env.example .env    # then edit .env, paste GEMINI_API_KEY
python -m uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

Verify: http://localhost:8000/api/health → `{"status":"healthy","gemini_key_configured":true,...}`.
Interactive API docs: http://localhost:8000/docs.

---

## Deploying the Backend to the Cloud

Required for shipping a release APK that works on any device.

| Host | Free? | Notes |
|---|---|---|
| Render | Yes (sleeps after 15 min) | Recommended — picks up FastAPI automatically |
| Fly.io | Yes | `flyctl launch` from `backend/` |
| Cloud Run | Pay-per-request | `gcloud run deploy --source .` |
| Railway | Limited free | Auto-detects FastAPI |

Render quickstart:
- **Type:** Web Service
- **Root Directory:** `backend`
- **Build Command:** `pip install -r requirements.txt`
- **Start Command:** `uvicorn main:app --host 0.0.0.0 --port $PORT`
- **Env vars:** `GEMINI_API_KEY=...`, `PYTHON_VERSION=3.11.9`
- **Health Check Path:** `/api/health`

Cold-start fix on free tier: point UptimeRobot at `/api/health` every 5 min so the dyno never sleeps.

Full step-by-step Render walkthrough: [RENDER-DEPLOYMENT.md](RENDER-DEPLOYMENT.md). Brief deploy template + alt-host notes: [mobile/.env.example](../mobile/.env.example).

---

## Running the Flutter App

### Prerequisites
- Flutter 3.x (stable)
- Android SDK (API 21+)
- Connected emulator or physical device

### Debug (local backend, auto-routed to 10.0.2.2:8000)

```powershell
cd mobile
flutter pub get
flutter run
```

### Release APK (cloud backend)

```powershell
cd mobile
Copy-Item .env.example .env          # then paste cloud URL into .env
flutter clean
flutter build apk --release
# APK at mobile/build/app/outputs/flutter-apk/app-release.apk
```

The Dart entry point ([main.dart](../mobile/lib/main.dart)) calls `dotenv.load(fileName: '.env')` before `runApp`. [api_service.dart](../mobile/lib/services/api_service.dart) reads `BASEERA_API_URL` from the loaded env in release mode and falls back to the debug URL in `kDebugMode`.

---

## Mock Data Sources

| File | Content | Credibility | Role |
|---|---|---|---|
| `warehouse_stock.csv` | 10 products, Basmati Rice = 1,200 units | **STALE** (3 days old) | The contradiction source |
| `supplier_email.json` | Ahmed Traders — 5-day delivery delay | **HIGH** | Corroborates supply gap |
| `sales_dashboard.json` | 180 units/day, 542 sold last 3 days | **HIGH** | Exposes stale CSV |
| `customer_complaints.json` | 47 "out of stock" complaints / 24h | **HIGH** | Confirms actual stockout |
| `market_news_feed.json` | Punjab transport strike news | **MEDIUM** | External corroboration |

**Core contradiction:** CSV says 1,200 units; complaints + sales prove the stock is near zero. Resolution: CSV is 3 days old, sales show 542 units moved in that window. Baseera flags `warehouse_stock.csv` as STALE / LOW credibility.

---

## Gemini API Integration

The backend calls Gemini 2.5 Flash:

1. **System instruction** defines the agent's role and enforces JSON-only output.
2. **User content** injects all 5 formatted data sources + the exact output schema.
3. Gemini returns a single structured JSON containing:
   - `sources_summary` — credibility assessment per source
   - `contradictions` — detected conflicts with resolution logic
   - `action_chain` — 4 prioritized steps
   - `before_state` / `after_state` — predicted outcome
   - `agent_trace` — step-by-step reasoning

A **fallback response** is hardcoded in [agents/gemini_client.py](../backend/agents/gemini_client.py) — if Gemini fails (quota, network, etc.), the app uses this fallback and shows a "Demo Mode" badge.

---

## Action Chain Simulation

Steps execute sequentially via `POST /api/execute-step`:

| Step | Action | Simulated Time |
|---|---|---|
| 1 | Emergency warehouse audit | 2s → Completed |
| 2 | Contact supplier / emergency procurement | 2s → **FAILED** → 2s → Completed |
| 3 | Update website + notify 847 customers | 2s → Completed |
| 4 | Activate automated monitoring | 2s → Completed |

---

## Failure Recovery Demonstration

**Step 2** fails on first attempt: `"Supplier API timeout — could not reach Ahmed Traders procurement portal"`.

**Flutter response:**
1. Shows **FAILED** state (red glow, `LucideIcons.xCircle`) for 3 seconds
2. Switches to **RETRYING** (gold glow, spinning `LucideIcons.refreshCw`)
3. Calls the API again
4. Backend returns **COMPLETED** with `completion_note: "Completed via email fallback channel"`
5. Card animates to green tint, shows the recovery note

Fully autonomous. No human intervention.

---

## UI/Theme

| Aspect | Detail |
|---|---|
| Theme | Premium royal dark (purple + gold accents) |
| Background | `#0A0A12` |
| Surface | `#0F0F1E` |
| Primary | `#6C3FE8` → `#9B6DFF` (gradient) |
| Gold | `#D4A017` → `#FFD060` (gradient text accents) |
| Typography | Outfit (Google Fonts) — UI + PDF |
| Icons | Lucide (`lucide_icons_flutter`) — zero emojis |
| Launcher icon bg | `#1A1035` |
| Splash | Native Android 12+ splash + Dart splash with fade transition to home |
| PDF | Outfit font via `PdfGoogleFonts` (full Unicode) |

---

## Known Limitations

1. **Android-only** — Flutter app targets Android. iOS would require macOS build env.
2. **Single session** — backend holds state in memory; restarting uvicorn resets all state.
3. **Simulated execution** — action steps use 2-second `sleep` delays. Gemini plans, execution is mocked.
4. **Render free-tier cold start** — first request after 15 min idle takes ~30s. Mitigate with UptimeRobot.
5. **Gemini rate limits** — free tier ~1,500 requests/day. Each app run = 1 Gemini call.
6. **Notifications mocked** — "847 customer notifications" are simulated numbers.

---

## Cost Estimate

| Item | Details | Cost |
|---|---|---|
| Gemini 2.5 Flash input | ~2,700 tokens / analysis | ~$0.0002 |
| Gemini 2.5 Flash output | ~800 tokens / analysis | ~$0.00024 |
| **Per session** | 1 API call | **~$0.0004 ≈ PKR 0.11** |
| **100 demo sessions** | Full hackathon demo day | **~PKR 11** |
| Render Web Service (Free) | 750 hrs/mo | $0 |
| Render Web Service (Starter) | Optional, no cold start | $7/mo |

---

## Project Structure

```
Baseera/
├── antigravity-logs/        Planning, decision, summary docs
├── backend/
│   ├── main.py
│   ├── agents/
│   │   ├── data_loader.py
│   │   ├── gemini_client.py
│   │   └── action_executor.py
│   ├── mock_data/           5 source files
│   ├── requirements.txt
│   ├── .env                 (gitignored) GEMINI_API_KEY
│   └── .env.example
├── mobile/
│   ├── lib/
│   │   ├── main.dart        dotenv.load → runApp
│   │   ├── models/
│   │   ├── services/api_service.dart   debug→localhost / release→cloud
│   │   ├── providers/
│   │   └── screens/
│   │       ├── splash_screen.dart
│   │       ├── home_screen.dart
│   │       ├── sources_screen.dart
│   │       ├── action_chain_screen.dart
│   │       └── outcome_screen.dart
│   ├── assets/
│   │   ├── logo.png
│   │   └── icon/
│   ├── android/             Generated launcher icons + splash drawables
│   ├── .env                 (gitignored) BASEERA_API_URL
│   ├── .env.example         Deploy steps in comments
│   └── pubspec.yaml
├── docs/
│   ├── README.md            This file
│   ├── architecture.md
│   └── TROUBLESHOOTING.md
├── demo-assets/
├── .gitignore
└── README.md                Top-level quick-start
```

---

*Built by: Krevon Studios | AISeekho 2026 Hackathon | Challenge 1*
