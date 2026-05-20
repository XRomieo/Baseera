# Baseera — Task List
## AISeekho 2026 | Challenge 1
### Timestamp: 2026-05-20T15:30:00+05:00

---

## Phase 0: Scaffolding & Logs

- [x] Create `antigravity-logs/` directory
- [x] Write `antigravity-logs/workplan.md`
- [x] Write `antigravity-logs/task-list.md` (this file)
- [x] Write `antigravity-logs/backend-decisions.md`
- [x] Write `antigravity-logs/flutter-decisions.md`
- [x] Write `antigravity-logs/gemini-prompt-design.md`
- [x] Write `antigravity-logs/failure-recovery-design.md`
- [ ] Write `antigravity-logs/final-summary.md` (after completion)
- [x] Create `demo-assets/` directory placeholder
- [x] Create `docs/` directory placeholder

---

## Phase 1: Mock Data

- [x] Create `backend/mock_data/warehouse_stock.csv`
  - Basmati Rice 5kg: 1200 units (STALE - 3 days ago)
  - 4 other products to appear realistic
  - Intentionally outdated date
- [x] Create `backend/mock_data/supplier_email.json`
  - From Ahmed Traders, Lahore
  - Delivery delayed 5 days
  - Transport issues cited
- [x] Create `backend/mock_data/sales_dashboard.json`
  - 7-day daily sales data
  - 180 units/day average for Basmati Rice
  - Last 3 days shows ~540 units sold
- [x] Create `backend/mock_data/customer_complaints.json`
  - 47 complaints about "out of stock"
  - Timestamped within last 24 hours
  - Customer IDs and messages
- [x] Create `backend/mock_data/market_news_feed.json`
  - Transport strike in Lahore news
  - Multiple news items
  - Corroborates supply delay

---

## Phase 2: Backend

### Setup
- [x] Create `backend/requirements.txt`
- [x] Create `backend/.env.example`
- [x] Create `backend/agents/` directory
- [x] Create `backend/agents/__init__.py`

### Agents
- [x] Create `backend/agents/data_loader.py`
  - [x] Load warehouse_stock.csv with pandas
  - [x] Load all 4 JSON files
  - [x] Return dict of source → content string
- [x] Create `backend/agents/gemini_client.py`
  - [x] Initialize Gemini 2.0 Flash model
  - [x] Build system prompt dynamically
  - [x] Send request to Gemini
  - [x] Parse and validate JSON response
  - [x] Implement fallback mock response
- [x] Create `backend/agents/action_executor.py`
  - [x] In-memory state dict
  - [x] Step execution with simulated delay
  - [x] Step 2 failure on first attempt
  - [x] Auto-retry logic
  - [x] Return updated state

### API
- [x] Create `backend/main.py`
  - [x] FastAPI app setup
  - [x] CORS middleware
  - [x] Load .env
  - [x] POST /api/analyze endpoint
  - [x] POST /api/execute-step endpoint
  - [x] GET /api/outcome endpoint
  - [x] Startup event to reset state

---

## Phase 3: Flutter App

### Setup
- [x] Create `mobile/pubspec.yaml`
  - dio, provider, shimmer, flutter_animate, google_fonts
  - Android SDK min 21
- [x] Update `mobile/android/app/build.gradle` (package name)

### Models
- [x] Create `mobile/lib/models/source_model.dart`
- [x] Create `mobile/lib/models/contradiction_model.dart`
- [x] Create `mobile/lib/models/action_step_model.dart`
- [x] Create `mobile/lib/models/analysis_result_model.dart`
- [x] Create `mobile/lib/models/outcome_model.dart`

### Services
- [x] Create `mobile/lib/services/api_service.dart`
  - [x] Dio client configured for localhost:8000
  - [x] POST /api/analyze
  - [x] POST /api/execute-step
  - [x] GET /api/outcome
  - [x] Error handling + fallback

### State Management
- [x] Create `mobile/lib/providers/analysis_provider.dart`
  - [x] AnalysisState enum
  - [x] Analysis result storage
  - [x] Step execution state
  - [x] Outcome data

### App Entry
- [x] Create `mobile/lib/main.dart`
  - [x] Provider setup
  - [x] MaterialApp with Material 3
  - [x] Theme with color scheme
  - [x] Routes

### Screens
- [x] Create `mobile/lib/screens/home_screen.dart`
  - [x] App name + icon
  - [x] Run Analysis button
  - [x] Status indicator
- [x] Create `mobile/lib/screens/sources_screen.dart`
  - [x] 5 source cards
  - [x] Shimmer animation
  - [x] Credibility badges
  - [x] Contradiction card
- [x] Create `mobile/lib/screens/action_chain_screen.dart`
  - [x] Vertical stepper
  - [x] Step status icons
  - [x] Auto-progression with delay
  - [x] Step 2 failure → retry → success
- [x] Create `mobile/lib/screens/outcome_screen.dart`
  - [x] Before/After layout
  - [x] Metrics with progress bars
  - [x] Agent Trace section
  - [x] Download Report button

### Widgets
- [x] Create `mobile/lib/widgets/source_card.dart`
- [x] Create `mobile/lib/widgets/contradiction_card.dart`
- [x] Create `mobile/lib/widgets/step_card.dart`
- [x] Create `mobile/lib/widgets/metric_comparison_card.dart`

---

## Phase 4: Documentation

- [x] Create `docs/README.md`
- [x] Create `docs/architecture.md`
- [x] Update `antigravity-logs/backend-decisions.md`
- [x] Update `antigravity-logs/flutter-decisions.md`
- [x] Update `antigravity-logs/gemini-prompt-design.md`
- [x] Update `antigravity-logs/failure-recovery-design.md`
- [ ] Write `antigravity-logs/final-summary.md`

---

## Final Checks

- [ ] Backend starts with `uvicorn main:app --reload`
- [ ] All 5 endpoints work correctly
- [ ] Gemini API key is loaded from .env
- [ ] Flutter app compiles without errors
- [ ] All 4 screens navigate correctly
- [ ] Step 2 failure + retry is visible
- [ ] Outcome dashboard shows all metrics
- [ ] All antigravity-logs/ files are complete

---

*Last updated: 2026-05-20T15:30:00+05:00*
