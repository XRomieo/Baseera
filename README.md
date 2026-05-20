# Baseera — AISeekho 2026 Hackathon | Challenge 1

**Autonomous Content-to-Action Agent**
AI-powered supply chain crisis detector. Reads 5 data sources, spots contradictions, resolves them with Gemini 2.5 Flash, executes a 4-step action chain — all autonomously. Premium royal dark theme, Lucide icon set, Outfit typography, Unicode-aware PDF reports.

---

## What It Does

1. **Analyzes 5 data sources** (warehouse CSV, supplier email, sales dashboard, customer complaints, market news) for contradictions.
2. **Resolves conflicts** with Gemini 2.5 Flash — picks the most credible source.
3. **Executes a 4-step action chain** autonomously (physical audit → supplier contact → customer notifications → monitoring).
4. **Handles failures gracefully** — Step 2 simulates a supplier API timeout and auto-retries via email fallback.
5. **Shows before/after outcomes** with animated metrics. Exports a branded PDF report.

---

## Project Structure

```
Baseera/
├── backend/                                # Python FastAPI backend
│   ├── agents/
│   │   ├── gemini_client.py                # Gemini API wrapper (new + legacy SDK fallback)
│   │   ├── action_executor.py              # 4-step engine with failure simulation
│   │   └── data_loader.py                  # Loads + formats mock data sources
│   ├── mock_data/                          # 5 source files (CSV + JSON)
│   ├── main.py                             # FastAPI app with 5 routes
│   ├── requirements.txt
│   ├── .env                                # ← YOU CREATE (gitignored)
│   └── .env.example                        # Template
├── mobile/                                 # Flutter Android app
│   ├── lib/
│   │   ├── main.dart                       # Entry, ThemeData, routing, dotenv load
│   │   ├── models/                         # Analysis, source, action, outcome models
│   │   ├── providers/analysis_provider.dart
│   │   ├── services/api_service.dart       # Dio + kDebugMode URL switch
│   │   └── screens/
│   │       ├── splash_screen.dart          # Dart splash with fade→home transition
│   │       ├── home_screen.dart
│   │       ├── sources_screen.dart
│   │       ├── action_chain_screen.dart
│   │       └── outcome_screen.dart
│   ├── assets/
│   │   ├── logo.png                        # App logo (eye)
│   │   └── icon/                           # Padded launcher icon + splash PNGs
│   ├── android/app/src/main/res/           # Generated launcher icons + splash drawables
│   ├── .env                                # ← YOU CREATE (gitignored, holds cloud URL)
│   ├── .env.example                        # Template + deploy steps in comments
│   └── pubspec.yaml
├── docs/
│   ├── README.md
│   ├── architecture.md
│   └── TROUBLESHOOTING.md
├── .gitignore
└── README.md                               # This file
```

---

## Prerequisites

| Tool | Version | Download |
|---|---|---|
| Python | 3.11+ | https://python.org/downloads |
| Java JDK | 17 or 21 | https://adoptium.net |
| Flutter | 3.x stable | https://docs.flutter.dev/get-started/install |
| Android Studio | Latest | https://developer.android.com/studio |
| Git | Any | https://git-scm.com |

> **Python 3.14 only:** set `$env:PYO3_USE_ABI3_FORWARD_COMPATIBILITY = "1"` before `pip install`.

---

## Setup

### 1. Clone

```powershell
git clone https://github.com/XRomieo/Baseera.git
cd Baseera
```

### 2. Backend

```powershell
cd backend
pip install -r requirements.txt
Copy-Item .env.example .env
```

Edit `backend/.env`:
```
GEMINI_API_KEY=your_gemini_api_key_here
```
Free key at https://aistudio.google.com/app/apikey.

### 3. Mobile

```powershell
cd mobile
flutter pub get
Copy-Item .env.example .env
```

`mobile/.env` is only needed for **release builds**. Debug builds (`flutter run`) ignore it and hit `http://10.0.2.2:8000` (emulator alias for host localhost).

---

## Running (Debug — Local Backend)

### Terminal 1 — Backend
```powershell
cd backend
python -m uvicorn main:app --reload --host 0.0.0.0 --port 8000
```
Verify: http://localhost:8000/api/health → `{"status":"healthy",...}`.

### Terminal 2 — Flutter
```powershell
cd mobile
flutter run
```
App auto-connects to `10.0.2.2:8000`. Tap **Run Analysis**.

---

## Building Release APK (Cloud Backend)

1. **Deploy the backend** to Render / Fly.io / Railway / Cloud Run. See `mobile/.env.example` for exact host configuration.
2. **Edit `mobile/.env`**:
   ```
   BASEERA_API_URL=https://your-deployed-backend.onrender.com
   ```
3. **Build**:
   ```powershell
   cd mobile
   flutter clean
   flutter build apk --release
   ```
4. APK at `mobile/build/app/outputs/flutter-apk/app-release.apk`. Install on any device with internet — no laptop or LAN needed.

### URL resolution logic

[mobile/lib/services/api_service.dart](mobile/lib/services/api_service.dart):
- `kDebugMode == true` → `http://10.0.2.2:8000` (hardcoded)
- `kDebugMode == false` → `BASEERA_API_URL` from `mobile/.env`
- Missing `.env` value → falls back to debug URL + logs a warning

---

## API Reference

| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/` | App info |
| `GET` | `/api/health` | Health check + Gemini key status |
| `POST` | `/api/analyze` | Trigger Gemini analysis of 5 sources |
| `POST` | `/api/execute-step` | Execute action step 1–4 |
| `GET` | `/api/outcome` | Before/after metrics |

---

## Environment Variables

### `backend/.env`
| Variable | Required | Description |
|---|---|---|
| `GEMINI_API_KEY` | Yes | Gemini API key from Google AI Studio |

### `mobile/.env`
| Variable | Required | Description |
|---|---|---|
| `BASEERA_API_URL` | Release builds only | HTTPS URL of deployed backend |

Both `.env` files are gitignored. Templates (`.env.example`) are committed.

---

## Flutter Dependencies

| Package | Purpose |
|---|---|
| `dio` | HTTP client |
| `provider` | State management |
| `shimmer` | Skeleton loaders |
| `flutter_animate` | One-shot UI animations |
| `google_fonts` | Outfit font |
| `lucide_icons_flutter` | Lucide icon set (no emojis anywhere) |
| `flutter_dotenv` | `.env` loader for cloud URL |
| `path_provider` | Temp dir for PDF |
| `pdf` | PDF generation |
| `printing` | `PdfGoogleFonts.outfit*` — Unicode font in PDFs |
| `share_plus` | Android share sheet |
| `flutter_launcher_icons` (dev) | Generates adaptive launcher icons |
| `flutter_native_splash` (dev) | Generates native Android 12+ splash |

---

## Theme

Royal dark palette, defined in [mobile/lib/main.dart](mobile/lib/main.dart) `BaseeraColors`:

| Token | Hex |
|---|---|
| Background | `#0A0A12` |
| Surface | `#0F0F1E` |
| Primary | `#6C3FE8` |
| Primary glow | `#9B6DFF` |
| Gold | `#D4A017` |
| Gold glow | `#FFD060` |
| Success | `#00C97A` |
| Error | `#FF4D6D` |
| Warning | `#FFA500` |
| Text primary | `#FFFFFF` |
| Text secondary | `#A89BC2` |
| Border | `#2A2040` |
| Launcher icon bg | `#1A1035` |

Typography: **Outfit** (Google Fonts) across UI + PDF.
Icons: **Lucide** exclusively. Zero emoji glyphs in the codebase.

---

## Tech Stack

| Layer | Technology |
|---|---|
| AI | Gemini 2.5 Flash (`google-genai` + `google-generativeai`) |
| Backend | Python 3.11+, FastAPI, Uvicorn |
| Mobile | Flutter 3.x, Dart |
| HTTP | Dio (Flutter), HTTPX (Python) |
| State | Provider |
| PDF | `dart-pdf` + `printing` (Outfit Unicode) + `share_plus` |

---

## Hackathon Context

**Challenge 1 — Autonomous Content-to-Action Agent**

Scenario: a Lahore grocery chain warehouse shows 1,200 units of Basmati Rice 5kg, but customers report stockouts, sales data shows the stock was depleted 3 days ago, and a supplier confirms a 5-day delivery delay. Baseera:
- Detects the contradiction
- Resolves it in favour of fresher, corroborating sources
- Autonomously executes a 4-step recovery plan
- Handles a supplier API failure (auto-retry via email fallback)
- Reduces stockout risk from 87% → 12%

---

## Further Docs

- [docs/architecture.md](docs/architecture.md) — system diagrams, state machines, design patterns
- [docs/RENDER-DEPLOYMENT.md](docs/RENDER-DEPLOYMENT.md) — step-by-step Render deployment guide
- [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) — common errors + fixes
- [mobile/.env.example](mobile/.env.example) — backend deploy template + alt-host notes

---

*Built for AISeekho 2026 | Powered by Gemini 2.5 Flash*
