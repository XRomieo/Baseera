# Baseera — AISeekho 2026 Hackathon | Challenge 1

**Autonomous Content-to-Action Agent**  
AI-powered supply chain crisis detector that reads 5 data sources, spots contradictions, resolves them using Gemini 2.5 Flash, and executes a 4-step action chain — all autonomously.

---

## What It Does

1. **Analyzes 5 data sources** (warehouse CSV, supplier email, sales dashboard, customer complaints, market news) for contradictions
2. **Resolves conflicts** using Gemini 2.5 Flash to determine which source is most credible
3. **Executes a 4-step action chain** autonomously (physical audit → supplier contact → customer notifications → monitoring)
4. **Handles failures gracefully** — Step 2 simulates a supplier API timeout and auto-retries via email fallback
5. **Shows before/after outcomes** with animated metrics and exports a branded PDF report

---

## Project Structure

```
AISeekho-2026/
├── backend/                    # Python FastAPI backend
│   ├── agents/
│   │   ├── gemini_client.py    # Gemini API wrapper (new + legacy SDK fallback)
│   │   ├── action_executor.py  # 4-step execution engine with failure simulation
│   │   └── data_loader.py      # Loads and formats mock data sources
│   ├── mock_data/              # 5 data source files (CSV + JSON)
│   │   ├── warehouse_stock.csv
│   │   ├── supplier_email.json
│   │   ├── sales_dashboard.json
│   │   ├── customer_complaints.json
│   │   └── market_news_feed.json
│   ├── main.py                 # FastAPI app with 5 routes
│   ├── requirements.txt
│   ├── .env                    # ← YOU CREATE THIS (gitignored)
│   └── .env.example            # Template for .env
├── mobile/                     # Flutter Android app
│   ├── lib/
│   │   ├── main.dart           # App entry, theme, routing
│   │   ├── models/             # Data models (analysis, source, action, outcome)
│   │   ├── providers/          # AnalysisProvider (state management)
│   │   ├── screens/            # 4 screens: upload, sources, action_chain, outcome
│   │   └── services/           # ApiService (Dio HTTP client)
│   ├── android/
│   │   ├── local.properties           # ← YOU CREATE THIS (gitignored)
│   │   └── local.properties.example   # Template
│   └── pubspec.yaml
├── .gitignore
└── README.md
```

---

## Prerequisites

Install all of these **system-wide** before cloning:

| Tool | Version | Download |
|------|---------|----------|
| Python | 3.12+ | https://python.org/downloads |
| Java (JDK) | 17 or 21 | https://adoptium.net |
| Flutter | 3.x stable | https://docs.flutter.dev/get-started/install |
| Android Studio | Latest | https://developer.android.com/studio |
| Git | Any | https://git-scm.com |

> **Python 3.14 note:** If using Python 3.14, set this before `pip install`:
> ```powershell
> $env:PYO3_USE_ABI3_FORWARD_COMPATIBILITY = "1"
> ```

---

## Setup

### 1 — Clone the repo

```powershell
git clone https://github.com/XRomieo/Baseera.git
cd Baseera
```

### 2 — Backend setup

```powershell
cd backend

# Install dependencies
pip install -r requirements.txt

# Create your .env file from the template
Copy-Item .env.example .env
```

Edit `backend/.env` and add your Gemini API key:

```env
GEMINI_API_KEY=your_gemini_api_key_here
```

Get a free key at: https://aistudio.google.com/app/apikey

### 3 — Mobile setup

Create `mobile/android/local.properties` from the template:

```powershell
Copy-Item mobile/android/local.properties.example mobile/android/local.properties
```

Edit `mobile/android/local.properties` with your actual paths:

```properties
flutter.sdk=C:\flutter
sdk.dir=D:\Android\Sdk
```

> **Find your Android SDK path:** Android Studio → Settings → Android SDK → SDK Location

Install Flutter dependencies:

```powershell
cd mobile
flutter pub get
```

---

## Running the App

### Step 1 — Start the backend

```powershell
cd backend
python -m uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

You should see:
```
INFO: Baseera backend started — state initialized
INFO: Gemini API Key: ✓ loaded
INFO: Application startup complete.
INFO: Uvicorn running on http://0.0.0.0:8000
```

Verify it's working: http://localhost:8000/api/health

### Step 2 — Launch the Flutter app

Open a **second terminal** and run:

```powershell
cd mobile
flutter run
```

> The app connects to the backend via `http://10.0.2.2:8000` (Android emulator's alias for `localhost`).
> If running on a **physical device**, update `lib/services/api_service.dart` to use your PC's local IP instead.

### Step 3 — Use the app

1. Tap **"Run Analysis"** on the home screen
2. Watch all 5 data sources load with shimmer animations
3. See the contradiction detected between sources
4. Tap **"Execute Action Chain"** to run all 4 steps
5. Watch Step 2 fail → auto-retry → succeed (designed to demo fault tolerance)
6. View the **Outcome Dashboard** with before/after metrics
7. Tap the **download icon** to export a PDF report via your device's share sheet

---

## API Reference

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/` | App info and endpoint list |
| `GET` | `/api/health` | Health check + API key status |
| `POST` | `/api/analyze` | Trigger Gemini analysis of 5 data sources |
| `POST` | `/api/execute-step` | Execute action step 1–4 |
| `GET` | `/api/outcome` | Get before/after metrics + step details |

---

## Environment Variables

### `backend/.env`

| Variable | Required | Description |
|----------|----------|-------------|
| `GEMINI_API_KEY` | Yes | Your Gemini API key from Google AI Studio |

---

## Flutter Dependencies

| Package | Purpose |
|---------|---------|
| `dio` | HTTP client for backend API calls |
| `provider` | State management |
| `shimmer` | Skeleton loading animations |
| `flutter_animate` | Smooth UI animations |
| `google_fonts` | Outfit font family |
| `path_provider` | Temp directory for PDF |
| `pdf` | PDF generation |
| `share_plus` | Android share sheet for PDF export |

---

## Troubleshooting

### `uvicorn` not found
```powershell
python -m uvicorn main:app --reload --host 0.0.0.0 --port 8000
```
Use `python -m uvicorn` instead of just `uvicorn`.

### `flutter doctor` shows Android toolchain errors
- Open Android Studio → SDK Manager → SDK Tools → check **Android SDK Command-line Tools**
- Set `ANDROID_HOME` environment variable to your SDK path (e.g. `D:\Android\Sdk`)

### App shows "Connection refused" / "Network error"
- Make sure the backend is running on port 8000
- On emulator, the backend URL is `10.0.2.2:8000` (already configured)
- On physical device, update `baseUrl` in `lib/services/api_service.dart` to your PC's IP

### PDF shows blank symbols (→, •, ⚠)
- This is fixed — the PDF uses ASCII-safe characters (`->`, `>`, `[!]`)

### `pydantic` install fails on Python 3.14
```powershell
$env:PYO3_USE_ABI3_FORWARD_COMPATIBILITY = "1"
pip install -r requirements.txt
```

### AGP / Kotlin warnings during `flutter run`
These are **warnings only** — the build still succeeds. They are about future Flutter deprecations, not current errors.

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| AI | Gemini 2.5 Flash (google-genai + google-generativeai SDKs) |
| Backend | Python 3.12+, FastAPI, Uvicorn |
| Mobile | Flutter 3.x, Dart |
| HTTP | Dio (Flutter), HTTPX (Python) |
| State | Provider pattern |
| PDF | dart-pdf + share_plus |

---

## Hackathon Context

**Challenge 1 — Autonomous Content-to-Action Agent**

The scenario: An e-commerce warehouse has conflicting data about Basmati Rice 5kg stock levels. The AI agent must:
- Detect that warehouse CSV (1,200 units) contradicts sales dashboard + customer complaints (effectively 0 units)
- Resolve the contradiction in favour of fresher, corroborating sources
- Autonomously execute a 4-step recovery plan
- Handle a supplier API failure gracefully (auto-retry via email fallback)
- Reduce stockout risk from 87% → 12%

---

*Built with ❤️ for AISeekho 2026 | Powered by Gemini 2.5 Flash*
