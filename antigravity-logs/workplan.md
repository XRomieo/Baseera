# Baseera — Full Implementation Workplan
## AISeekho 2026 | Challenge 1: Autonomous Content-to-Action Agent
### Timestamp: 2026-05-20T15:30:00+05:00

---

## Executive Summary

Baseera is a production-ready demonstration of an Autonomous Content-to-Action Agent built for the AISeekho 2026 Google Antigravity Hackathon.

The system:
1. Ingests 5 simultaneous mock data sources from a Pakistani retail supply chain scenario
2. Sends all data to Gemini 2.0 Flash for multi-source intelligence extraction
3. Detects contradictions (stale warehouse data vs. live customer complaints)
4. Generates a prioritized 4-step action chain
5. Simulates execution step-by-step with visible state transitions
6. Demonstrates failure recovery (Step 2 fails → retries → succeeds)
7. Shows a before/after outcome dashboard with real metrics

---

## Architecture Overview

```
Flutter Android App
    │
    │ HTTP (Dio + REST)
    ▼
FastAPI Backend (:8000)
    ├── POST /api/analyze      → Load 5 sources → Gemini → Return JSON
    ├── POST /api/execute-step → Simulate step with delay + failure
    └── GET  /api/outcome      → Return before/after metrics
    │
    ▼
Google Gemini 2.0 Flash API
    │
    ▼
backend/mock_data/ (5 JSON/CSV files)
```

---

## Build Phases

### Phase 0 — Project Scaffolding (Now)
- [x] Create folder structure
- [x] Write workplan.md (this file)
- [x] Write task-list.md
- [x] Write backend-decisions.md
- [x] Write flutter-decisions.md
- [x] Write gemini-prompt-design.md
- [x] Write failure-recovery-design.md

### Phase 1 — Mock Data Creation
Create 5 realistic mock data files in backend/mock_data/:

**warehouse_stock.csv**
- Basmati Rice 5kg: 1200 units
- Date: 3 days ago (STALE — this is the intentional lie)
- Multiple other products to look realistic
- Credibility: LOW (due to staleness)

**supplier_email.json**
- From: Ahmed Traders, Lahore
- Subject: Delivery Delay Notice
- Delivery delayed by 5 days due to transport issues
- Credibility: HIGH (direct vendor communication, dated today)

**sales_dashboard.json**
- 7-day average sales: 180 units/day for Basmati Rice 5kg
- Total sold last 3 days: ~540 units (which should have depleted the 1200 stock significantly)
- Credibility: HIGH (real-time system data)

**customer_complaints.json**
- 47 complaints in last 24 hours: "out of stock"
- Timestamps: today, recent hours
- Credibility: HIGH (direct customer signal, real-time)

**market_news_feed.json**
- Transport strike in Lahore affecting Punjab supply chains
- Confirms delay corroboration
- Credibility: MEDIUM (external news, not company-specific)

**The Core Contradiction**:
warehouse_stock.csv claims 1200 units available.
sales_dashboard.json shows 540 units sold in last 3 days alone (when stock was "1200").
customer_complaints.json shows 47 people getting "out of stock" errors.
→ CONCLUSION: Actual stock is 0 or near-zero. The warehouse CSV is stale by 3 days.

### Phase 2 — FastAPI Backend

**backend/agents/data_loader.py**
- Reads CSV with pandas
- Reads all JSON files
- Returns dict of source name → content string

**backend/agents/gemini_client.py**
- Uses google-generativeai SDK
- Constructs system prompt + data payload
- Enforces JSON output via response schema or prompt engineering
- Has fallback mock response if API fails

**backend/agents/action_executor.py**
- In-memory state: Dict[int, StepState]
- Step execution: async simulation with asyncio.sleep(2)
- Step 2 first-attempt failure logic using attempt counter
- Auto-retry mechanism

**backend/main.py**
- FastAPI app with CORS
- Loads .env for GEMINI_API_KEY
- POST /api/analyze
- POST /api/execute-step
- GET /api/outcome
- Startup: reset in-memory state

### Phase 3 — Flutter App

**Screens**:
1. HomeScreen — "Run Analysis" CTA, status indicator
2. SourcesScreen — 5 source cards with shimmer + credibility badges + contradiction card
3. ActionChainScreen — vertical stepper, 4 steps, auto-execute with delay
4. OutcomeScreen — before/after metrics, agent trace, download button

**State**: Provider with AnalysisProvider
**HTTP**: Dio with base URL http://10.0.2.2:8000 (Android emulator localhost)
**Design**: Material 3, deep blue primary, Google Fonts Outfit

### Phase 4 — Documentation
- docs/README.md
- docs/architecture.md
- All antigravity-logs/ files

---

## Timeline (Estimated)

| Phase | Estimated Time |
|-------|---------------|
| Scaffolding + Logs | 10 min |
| Mock Data | 10 min |
| Backend | 30 min |
| Flutter App | 60 min |
| Documentation | 20 min |
| **Total** | **~2 hours** |

---

## Risk Register

| Risk | Mitigation |
|------|-----------|
| Gemini API quota exceeded | Hardcoded fallback JSON in gemini_client.py |
| Flutter build issues | Ensure SDK compat, use stable Flutter channel |
| Android emulator localhost | Use 10.0.2.2 instead of localhost for Android |
| CORS issues | Add CORSMiddleware to FastAPI |
| Gemini returns non-JSON | Use explicit JSON-only prompt + response cleaning |

---

## Gemini API Strategy
- Model: gemini-2.0-flash (faster and cheaper)
- Call type: Single combined call with all 5 sources
- Output format: Strict JSON (enforced via prompt)
- Timeout: 30 seconds (backend) / 60 seconds (Flutter Dio)
- Cost per session: ~1 Gemini API call (~2000 input tokens, ~800 output tokens)
  Estimated cost: < $0.01 USD per run ≈ PKR 2.8

---

*Last updated: 2026-05-20T15:30:00+05:00*
*Agent: Antigravity (Google DeepMind)*
