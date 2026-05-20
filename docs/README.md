# Baseera
### AISeekho 2026 Google Antigravity Hackathon — Challenge 1: Autonomous Content-to-Action Agent

---

## 📌 Project Overview

**Baseera** is a production-ready autonomous business intelligence system built for the AISeekho 2026 Hackathon. It demonstrates how an AI agent can simultaneously ingest multiple conflicting data sources, detect contradictions using credibility reasoning, generate a prioritized action chain, and autonomously execute those actions — including recovering from failures without human intervention.

The scenario is grounded in Pakistani retail: a Lahore-based grocery chain faces a critical supply chain crisis. Their warehouse system shows 1,200 units of Basmati Rice 5kg in stock — but customers are flooding the support team with "out of stock" errors, a supplier has confirmed a 5-day delivery delay due to a Punjab transport strike, and sales data shows the stock should have been depleted 3 days ago. Baseera detects this contradiction, identifies the stale warehouse data as the culprit, and autonomously executes a 4-step recovery plan.

**Tech Stack**: Flutter 3.x (Android) + Python 3.11 FastAPI + Google Gemini 2.0 Flash API

---

## 🏗 Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    Baseera Flutter App                       │
│                                                                   │
│  ┌──────────┐   ┌──────────────┐  ┌──────────────┐  ┌────────┐ │
│  │  Home    │──▶│ Data Sources │─▶│ Action Chain │─▶│Outcome │ │
│  │Dashboard │   │   Screen     │  │   Screen     │  │ Screen │ │
│  └──────────┘   └──────────────┘  └──────────────┘  └────────┘ │
│                                                                   │
│  State: Provider (AnalysisProvider)                              │
│  HTTP:  Dio → http://10.0.2.2:8000 (Android emulator)           │
└───────────────────────────┬─────────────────────────────────────┘
                            │ REST API (JSON)
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│              FastAPI Backend (:8000)                              │
│                                                                   │
│  POST /api/analyze     → Load 5 sources + Gemini call            │
│  POST /api/execute-step → Step simulation (Step 2 fails+retries) │
│  GET  /api/outcome     → Before/After metrics                    │
│                                                                   │
│  agents/data_loader.py    → Reads 5 mock data files              │
│  agents/gemini_client.py  → Gemini 2.0 Flash integration         │
│  agents/action_executor.py → Step simulation + state machine     │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│              backend/mock_data/ (5 files)                         │
│                                                                   │
│  warehouse_stock.csv      ← STALE (3 days old, 1200 units)       │
│  supplier_email.json      ← Delivery delayed 5 days              │
│  sales_dashboard.json     ← 180 units/day, 542 sold in 3 days    │
│  customer_complaints.json ← 47 "out of stock" errors in 24h     │
│  market_news_feed.json    ← Punjab transport strike news         │
└─────────────────────────────────────────────────────────────────┘
                            │
                            ▼
                Google Gemini 2.0 Flash API
```

---

## 🚀 How to Run the Backend

### Prerequisites
- Python 3.11+
- pip

### Steps

```bash
# 1. Navigate to backend directory
cd backend

# 2. Create virtual environment (recommended)
python -m venv venv
venv\Scripts\activate    # Windows
# source venv/bin/activate  # Linux/Mac

# 3. Install dependencies
pip install -r requirements.txt

# 4. Set up environment (API key is already in .env)
# .env already contains: GEMINI_API_KEY=...

# 5. Run the backend
uvicorn main:app --reload --host 0.0.0.0 --port 8000

# 6. Verify it's running
# Open http://localhost:8000 in browser
# Open http://localhost:8000/docs for interactive API docs
```

The backend will:
- Log startup messages including Gemini API key status
- Be accessible at `http://localhost:8000`
- Auto-reload on file changes (dev mode)

---

## 📱 How to Build the Flutter APK

### Prerequisites
- Flutter 3.x (stable channel)
- Android SDK (API 21+)
- Android Studio or VS Code with Flutter extension
- A connected Android device or emulator running

### Steps

```bash
# 1. Navigate to mobile directory
cd mobile

# 2. Get Flutter dependencies
flutter pub get

# 3. Check Flutter environment
flutter doctor

# 4. Make sure Android emulator is running (or device connected)
# Start emulator: android avd (from Android Studio)

# 5. Run the app in debug mode
flutter run

# 6. Build release APK (for submission)
flutter build apk --release

# APK will be at:
# mobile/build/app/outputs/flutter-apk/app-release.apk
```

### Important: Backend URL Configuration
The app is configured to connect to `http://10.0.2.2:8000` which is the Android emulator's address for the host machine's localhost. If using a **physical device**, update the URL in `mobile/lib/services/api_service.dart`:

```dart
// Change this line:
const String _baseUrl = 'http://10.0.2.2:8000';
// To your machine's LAN IP, e.g.:
const String _baseUrl = 'http://192.168.1.100:8000';
```

---

## 📊 Mock Data Sources

| File | Content | Credibility | Key Role |
|------|---------|-------------|----------|
| `warehouse_stock.csv` | 10 products, Basmati Rice = 1,200 units | **STALE** (3 days old) | Source of the contradiction |
| `supplier_email.json` | Ahmed Traders confirms 5-day delivery delay | **HIGH** | Corroborates supply gap |
| `sales_dashboard.json` | 180 units/day avg, 542 sold in last 3 days | **HIGH** | Exposes stale warehouse data |
| `customer_complaints.json` | 47 "out of stock" complaints in 24 hours | **HIGH** | Confirms actual stockout |
| `market_news_feed.json` | Punjab transport strike news (5 articles) | **MEDIUM** | External corroboration |

**The Core Contradiction**: `warehouse_stock.csv` says 1,200 units. `customer_complaints.json` and `sales_dashboard.json` together prove the stock is at or near zero. The resolution: the warehouse CSV is 3 days old, and sales data shows ~542 units were sold in that window. Baseera detects this and flags `warehouse_stock.csv` as STALE with LOW credibility.

---

## 🤖 Gemini API Integration

The backend calls Gemini 2.0 Flash with a carefully engineered prompt:

1. **System instruction** defines the agent's role and enforces JSON-only output
2. **User content** injects all 5 formatted data sources + the exact output schema
3. Gemini returns a single structured JSON containing:
   - `sources_summary`: credibility assessment of each source
   - `contradictions`: detected conflicts with resolution logic
   - `action_chain`: 4 prioritized steps
   - `before_state` / `after_state`: predicted outcome
   - `agent_trace`: step-by-step reasoning log

A **fallback response** is hardcoded in `agents/gemini_client.py` — if Gemini fails for any reason (quota, network, etc.), the app uses this fallback and shows a "⚠ Demo Mode" badge.

---

## ⚡ Action Chain Simulation

The 4 steps execute sequentially via `POST /api/execute-step`:

| Step | Action | Simulated Time |
|------|--------|---------------|
| 1 | Emergency warehouse audit | 2 seconds → Completed |
| 2 | Contact supplier / emergency procurement | 2 seconds → **FAILED** → 2 seconds → Completed |
| 3 | Update website + notify 847 customers | 2 seconds → Completed |
| 4 | Activate automated monitoring | 2 seconds → Completed |

---

## 🔄 Failure Recovery Demonstration

**Step 2 fails on first attempt** with: `"Supplier API timeout — could not reach Ahmed Traders procurement portal"`

**Flutter response**:
1. Shows ❌ **FAILED** state for 3 seconds
2. Automatically switches to ↺ **RETRYING** state
3. Calls the API again (2nd attempt)
4. Backend returns ✓ **COMPLETED** with `completion_note: "Completed via email fallback channel"`
5. Flutter shows ✅ **Completed** with the recovery note

No human intervention required — fully autonomous recovery.

---

## ⚠️ Known Limitations

1. **Android-only**: The Flutter app targets Android. iOS would require a macOS build environment.
2. **Single session**: The backend holds state in memory; restarting uvicorn resets all state.
3. **No real AI execution**: The action steps are simulated (2-second delay each). Gemini provides the plan; execution is mocked.
4. **10.0.2.2 localhost**: Physical device testing requires updating the backend URL in `api_service.dart`.
5. **Gemini rate limits**: Free tier allows ~1,500 requests/day. Each app run = 1 Gemini call.
6. **No push notifications**: The "847 customer notifications" are simulated numbers, not real SMS/emails.

---

## 💰 Cost Estimate

| Item | Details | Cost |
|------|---------|------|
| Gemini 2.0 Flash input | ~2,700 tokens per analysis | ~$0.0002 |
| Gemini 2.0 Flash output | ~800 tokens per analysis | ~$0.00024 |
| **Per session total** | 1 API call | **~$0.0004 ≈ PKR 0.11** |
| **100 demo sessions** | Full hackathon demo day | **~PKR 11** |

Cost is negligible. The Gemini free tier (if using a free API key) allows ~1,500 requests/day which is sufficient for any demo scenario.

---

## 📁 Project Structure

```
AISeekho-2026/
├── antigravity-logs/       ← All planning, decision, and summary docs
│   ├── workplan.md
│   ├── task-list.md
│   ├── backend-decisions.md
│   ├── flutter-decisions.md
│   ├── gemini-prompt-design.md
│   ├── failure-recovery-design.md
│   └── final-summary.md
├── mobile/                 ← Flutter Android app
│   ├── lib/
│   │   ├── main.dart
│   │   ├── models/
│   │   ├── services/
│   │   ├── providers/
│   │   └── screens/
│   ├── android/
│   └── pubspec.yaml
├── backend/                ← Python FastAPI backend
│   ├── main.py
│   ├── agents/
│   │   ├── data_loader.py
│   │   ├── gemini_client.py
│   │   └── action_executor.py
│   ├── mock_data/
│   │   ├── warehouse_stock.csv
│   │   ├── supplier_email.json
│   │   ├── sales_dashboard.json
│   │   ├── customer_complaints.json
│   │   └── market_news_feed.json
│   ├── requirements.txt
│   └── .env
├── docs/
│   ├── README.md
│   └── architecture.md
└── demo-assets/
```

---

*Built by: Krevon Studios | AISeekho 2026 Hackathon | Challenge 1*
