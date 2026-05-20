# System Architecture — Baseera
## AISeekho 2026 Hackathon | Challenge 1

---

## High-Level System Design

```
                    ┌─────────────────────────────────────┐
                    │         Android Device/Emulator       │
                    │                                       │
                    │   ┌─────────────────────────────┐   │
                    │   │  Baseera Flutter App    │   │
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
                  ┌────────────────▼─────────────────────┐
                  │    http://10.0.2.2:8000 (emulator)    │
                  │    http://[LAN_IP]:8000 (device)      │
                  └────────────────┬─────────────────────┘
                                   │
                  ┌────────────────▼─────────────────────┐
                  │          FastAPI Backend               │
                  │                                       │
                  │  Endpoints:                           │
                  │  POST /api/analyze                    │
                  │  POST /api/execute-step               │
                  │  GET  /api/outcome                    │
                  │  GET  /api/health                     │
                  │                                       │
                  │  CORS: Allow-All (demo mode)          │
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
   │• Format   │   │  2.0 Flash    │  │• Step 2 failure  │
   │  for LLM  │   │• Parse JSON   │  │  recovery logic  │
   │           │   │• Fallback     │  │• Outcome metrics │
   └─────┬─────┘   └───────┬───────┘  └──────────────────┘
         │                 │
         ▼                 ▼
  mock_data/       Gemini 2.0 Flash API
  (5 files)        (Google Cloud)
```

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
  │                     │                      │ Generate
  │                     │                      │ analysis
  │                     │◀──────────────────────│ JSON
  │                     │                      │
  │                     │  Parse + validate    │
  │                     │  JSON response       │
  │                     │──────────────┐       │
  │                     │◀─────────────┘       │
  │                     │                      │
  │  AnalysisResult     │                      │
  │  JSON (sources,     │                      │
  │  contradictions,    │                      │
  │  action_chain...)   │                      │
  │◀────────────────────│                      │
```

---

## Step Execution State Machine

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
                 YES      │         │ NO
                          │         ▼
               ┌──────────┘    ┌──────────────┐
               │               │ Mark COMPLETED│
               ▼               └──────────────┘
  ┌─────────────────────────┐
  │ Is _step2_retry_count   │
  │ == 0?                   │
  └────────────┬────────────┘
         YES   │    NO
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
  POST /api/execute-step (step_number=2 again)
  → retry_count now == 1 → COMPLETED
```

---

## Flutter Screen State Transitions

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

## Dependency Graph

```
main.dart
├── AnalysisProvider (ChangeNotifier)
│   └── ApiService (Dio)
│       └── FastAPI Backend
│           ├── data_loader.py
│           │   └── mock_data/*.json, *.csv
│           ├── gemini_client.py
│           │   └── google.generativeai SDK
│           │       └── Gemini 2.0 Flash
│           └── action_executor.py
│               └── in-memory state dict
│
└── Screens
    ├── HomeScreen → AnalysisProvider
    ├── SourcesScreen → AnalysisProvider.analysisResult
    ├── ActionChainScreen → AnalysisProvider.steps
    └── OutcomeScreen → AnalysisProvider.outcomeModel
```

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
The ProxyProvider pattern allows `AnalysisProvider` to receive `ApiService` via dependency injection without a service locator.

### 2. Fallback-First API Design
```python
try:
    result = await call_gemini(sources)
except Exception:
    result = FALLBACK_RESPONSE  # Never crashes the demo
```

### 3. Step 2 Failure — Module-Level Counter
```python
_step2_retry_count: int = 0  # Module-level, persists across requests

async def execute_step(step_number: int):
    global _step2_retry_count
    if step_number == 2 and _step2_retry_count == 0:
        _step2_retry_count += 1
        return {"status": "failed", "should_retry": True}
    # second call: succeed
```

---

*Architecture Version 1.0 | Built for AISeekho 2026*
