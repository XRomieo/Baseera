# System Architecture — Baseera
## AISeekho 2026 Hackathon | Challenge 1

---

## High-Level System Design

```
                    ┌─────────────────────────────────────┐
                    │      Android Device / Emulator        │
                    │                                       │
                    │   ┌─────────────────────────────┐   │
                    │   │     Baseera Flutter App       │   │
                    │   │                             │   │
                    │   │  Provider State Management  │   │
                    │   │  ┌─────────────────────┐   │   │
                    │   │  │  AnalysisProvider   │   │   │
                    │   │  │  • AppState enum    │   │   │
                    │   │  │  • AnalysisResult   │   │   │
                    │   │  │  • ActionSteps[]    │   │   │
                    │   │  │  • OutcomeModel     │   │   │
                    │   │  └─────────────────────┘   │   │
                    │   │                             │   │
                    │   │  Screens (linear flow)      │   │
                    │   │  SplashScreen               │   │
                    │   │    ↓ (1.9s + fade/scale)    │   │
                    │   │  HomeScreen                 │   │
                    │   │    ↓ (Run Analysis)         │   │
                    │   │  SourcesScreen              │   │
                    │   │    ↓ (Execute Chain)        │   │
                    │   │  ActionChainScreen          │   │
                    │   │    ↓ (View Outcome)         │   │
                    │   │  OutcomeScreen              │   │
                    │   │    ↓ (Run Again)            │   │
                    │   │  HomeScreen                 │   │
                    │   └─────────────────────────────┘   │
                    │              │                       │
                    │         Dio HTTP Client              │
                    └──────────────┼──────────────────────┘
                                   │
                ┌──────────────────┴──────────────────────┐
                │  URL chosen at runtime by ApiService:    │
                │    kDebugMode == true  → 10.0.2.2:8000   │
                │    kDebugMode == false → dotenv          │
                │                          BASEERA_API_URL │
                └──────────────────┬──────────────────────┘
                                   │
                  ┌────────────────▼─────────────────────┐
                  │     FastAPI Backend                    │
                  │     (local :8000  OR  cloud HTTPS)     │
                  │                                       │
                  │  Endpoints:                           │
                  │   POST /api/analyze                   │
                  │   POST /api/execute-step              │
                  │   GET  /api/outcome                   │
                  │   GET  /api/health                    │
                  │                                       │
                  │  CORS: Allow-All (demo)               │
                  │  State: In-memory Python dicts        │
                  │  Async: asyncio (FastAPI native)      │
                  └────────┬─────────────────────────────┘
                           │
           ┌───────────────┼───────────────────┐
           │               │                   │
           ▼               ▼                   ▼
   ┌───────────┐   ┌───────────────┐  ┌──────────────────┐
   │data_loader│   │gemini_client  │  │action_executor   │
   │.py        │   │.py            │  │.py               │
   │           │   │               │  │                  │
   │• Load CSV │   │• Build prompt │  │• In-memory state │
   │• Load JSON│   │• Call Gemini  │  │• Step simulation │
   │• Format   │   │  2.5 Flash    │  │• Step 2 failure  │
   │  for LLM  │   │• Parse JSON   │  │  recovery logic  │
   │           │   │• Fallback     │  │• Outcome metrics │
   └─────┬─────┘   └───────┬───────┘  └──────────────────┘
         │                 │
         ▼                 ▼
  mock_data/       Gemini 2.5 Flash API
  (5 files)        (Google Cloud)
```

---

## Base URL Resolution (mobile)

```
ApiService constructor
        │
        ▼
   _resolveBaseUrl()
        │
        ├── kDebugMode == true  ─────► return 'http://10.0.2.2:8000'
        │
        ├── kDebugMode == false
        │     │
        │     ▼
        │   dotenv.maybeGet('BASEERA_API_URL')
        │     │
        │     ├── value present  ─────► return value
        │     │
        │     └── value missing  ─────► log warning, return debug URL
```

Source: [mobile/lib/services/api_service.dart](../mobile/lib/services/api_service.dart).
`.env` file loaded once in `main()` via `dotenv.load(fileName: '.env')` before `runApp`.

---

## Data Flow — POST /api/analyze

```
Client                Backend              Gemini API
  │                     │                      │
  │  POST /api/analyze  │                      │
  │────────────────────▶│                      │
  │                     │  Load 5 mock files   │
  │                     │──────────────┐       │
  │                     │◀─────────────┘       │
  │                     │                      │
  │                     │  Build prompt with   │
  │                     │  all source content  │
  │                     │──────────────────────▶│
  │                     │                      │  Generate
  │                     │                      │  analysis
  │                     │◀──────────────────────│  JSON
  │                     │                      │
  │                     │  Parse + validate    │
  │                     │  JSON response       │
  │                     │──────────────┐       │
  │                     │◀─────────────┘       │
  │                     │                      │
  │   AnalysisResult    │                      │
  │   JSON              │                      │
  │◀────────────────────│                      │
```

---

## Step Execution State Machine (backend)

```
              POST /api/execute-step (step_number=N)
                              │
                              ▼
                    ┌─────────────────┐
                    │   Mark RUNNING  │
                    └────────┬────────┘
                             │ asyncio.sleep(2)
                             ▼
              ┌──────────────────────────┐
              │   Is this step 2?        │
              └──────────┬─────────┬─────┘
                 YES     │         │ NO
                         │         ▼
              ┌──────────┘    ┌──────────────┐
              │               │ Mark COMPLETED│
              ▼               └──────────────┘
  ┌─────────────────────────┐
  │ Is _step2_retry_count   │
  │ == 0?                   │
  └────────────┬────────────┘
        YES    │    NO
               │    │
               │    ▼
               │ ┌──────────────────┐
               │ │ Mark COMPLETED   │
               │ │ (email fallback) │
               │ └──────────────────┘
               │
               ▼
  ┌──────────────────────────┐
  │ Increment retry_count    │
  │ Mark FAILED              │
  │ Return should_retry:true │
  └──────────────────────────┘
               │
               │ (Flutter waits 3s, retries)
               │
               ▼
  POST /api/execute-step (step_number=2)
  → retry_count now == 1 → COMPLETED
```

---

## Flutter App State Transitions

```
AppState.idle
  │ runAnalysis() called
  ▼
AppState.analyzing
  │ API returns success
  ▼
AppState.analyzed
  │ User taps "Execute Action Chain"
  ▼
AppState.executing
  │ All 4 steps complete
  ▼
AppState.executionComplete
  │ User taps "Run Again"
  ▼
AppState.idle (reset)
```

---

## Splash → Home Transition

```
App launch
  │
  ▼
Native Android splash       (windowSplashScreen, ~200-400 ms)
  │ Theme.Black.NoTitleBar, windowSplashScreenBackground=#0A0A12
  │ Drawable: assets/icon/splash.png (logo + "Baseera" wordmark + tagline)
  ▼
Flutter engine boots
  │ main() → dotenv.load → runApp(BaseeraApp)
  ▼
SplashScreen (Dart)         (1.9 s)
  │ Logo fade+scale, "Baseera" gold gradient (slide-up),
  │ tagline, loading spinner, "AISEEKHO 2026" footer
  ▼
Navigator.pushReplacement(PageRouteBuilder(
   transitionsBuilder: FadeTransition + ScaleTransition (1.04→1.0)
))                           (700 ms)
  ▼
HomeScreen
```

Source: [mobile/lib/screens/splash_screen.dart](../mobile/lib/screens/splash_screen.dart).

---

## Dependency Graph

```
main.dart  (loads .env via flutter_dotenv → runApp)
├── AnalysisProvider (ChangeNotifier)
│   └── ApiService (Dio)
│       ├── _resolveBaseUrl()  (kDebugMode + dotenv)
│       └── FastAPI Backend
│           ├── data_loader.py
│           │   └── mock_data/*.json, *.csv
│           ├── gemini_client.py
│           │   └── google.generativeai SDK
│           │       └── Gemini 2.5 Flash
│           └── action_executor.py
│               └── in-memory state dict
│
└── Screens
    ├── SplashScreen      → animated entry, pushes Home
    ├── HomeScreen        → AnalysisProvider
    ├── SourcesScreen     → AnalysisProvider.analysisResult
    ├── ActionChainScreen → AnalysisProvider.steps
    └── OutcomeScreen     → AnalysisProvider.outcomeModel
                            └── PDF via dart-pdf + PdfGoogleFonts.outfit*
```

---

## Theme & Asset Pipeline

```
assets/logo.png                                       (master eye logo)
  │
  ├── PowerShell System.Drawing pad scripts (once)
  │     │
  │     ├──► assets/icon/app_icon.png                 (1024² padded ~70 %)
  │     ├──► assets/icon/app_icon_foreground.png      (1024² padded ~53 %)
  │     └──► assets/icon/splash.png                   (1152² logo+wordmark)
  │
  ├── flutter_launcher_icons:
  │     image_path                = app_icon.png
  │     adaptive_icon_foreground  = app_icon_foreground.png
  │     adaptive_icon_background  = #1A1035
  │     min_sdk_android           = 21
  │       │
  │       └──► android/app/src/main/res/mipmap-*/ic_launcher*.png
  │              + drawable-*/ic_launcher_foreground.png
  │              + mipmap-anydpi-v26/ic_launcher.xml
  │              + values/colors.xml  (ic_launcher_background = #1A1035)
  │
  ├── flutter_native_splash:
  │     color                     = #0A0A12
  │     image                     = assets/icon/splash.png
  │     android_12.image          = assets/icon/splash.png
  │       │
  │       └──► android/app/src/main/res/drawable*/launch_background.xml
  │              + values{,-night,-v31,-night-v31}/styles.xml
  │
  └── runtime UI uses `assets/logo.png` directly in SplashScreen + HomeScreen
```

styles.xml `LaunchTheme` parent is forced to `Theme.Black.NoTitleBar` in `values-v31/` (default light parent caused white system flash before splash).

---

## Key Design Patterns

### 1. Provider + Proxy Provider
```dart
MultiProvider(
  providers: [
    Provider<ApiService>(create: (_) => ApiService()),
    ChangeNotifierProxyProvider<ApiService, AnalysisProvider>(
      create: (ctx) => AnalysisProvider(ctx.read<ApiService>()),
      update: ...
    ),
  ],
)
```
`AnalysisProvider` receives `ApiService` via DI — no service locator.

### 2. Fallback-First API Design
```python
try:
    result = await call_gemini(sources)
except Exception:
    result = FALLBACK_RESPONSE  # Never crashes the demo
```

### 3. Step 2 Failure — Module-Level Counter
```python
_step2_retry_count: int = 0  # persists across requests

async def execute_step(step_number: int):
    global _step2_retry_count
    if step_number == 2 and _step2_retry_count == 0:
        _step2_retry_count += 1
        return {"status": "failed", "should_retry": True}
    # second call: succeed
```

### 4. Debug/Release URL Split (Mobile)
- Debug builds bake `http://10.0.2.2:8000` into the Dart binary.
- Release builds read `BASEERA_API_URL` from `mobile/.env` (bundled as a Flutter asset, loaded by `flutter_dotenv` at startup).
- `.env` is gitignored; `.env.example` is the template + setup guide.

### 5. Performance Discipline (Mobile)
- No `AnimatedBuilder` wrapping subtrees that include animated `BoxShadow.blurRadius` (blur is GPU-expensive every frame).
- `IntrinsicHeight` only when necessary; left-accent stripes use `Stack` + `Positioned` instead of `Row(crossAxisAlignment: stretch)` + `IntrinsicHeight`.
- One-shot entrance animations via `flutter_animate` (fade/slide finish in ~600 ms then stop).
- `RotationTransition` (compositor-only) for spinning icons — no per-frame rebuilds.
- `RepaintBoundary` around isolated animated widgets (Run button, radial spotlight) so they don't invalidate parents.
- `TweenAnimationBuilder` for one-shot progress bar fills.

---

*Architecture Version 1.1 | Built for AISeekho 2026*
