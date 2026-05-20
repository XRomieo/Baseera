# Backend Architectural Decisions
## Baseera — AISeekho 2026
### Timestamp: 2026-05-20T15:31:00+05:00

---

## Decision 1: FastAPI over Flask

**Chosen**: FastAPI  
**Rejected**: Flask, Django REST Framework

**Rationale**:
- Native async/await support via Starlette — critical for Gemini API calls which are I/O bound
- Pydantic models give automatic request/response validation
- Auto-generated OpenAPI docs at /docs endpoint (useful for debugging during hackathon)
- Type hints throughout reduce bugs
- Performance: FastAPI is ~3x faster than Flask for async endpoints

---

## Decision 2: Google Generativeai SDK over Direct HTTP

**Chosen**: `google-generativeai` Python SDK  
**Rejected**: Direct `httpx` calls to Gemini REST API

**Rationale**:
- Official SDK handles auth, retries, and streaming automatically
- Less boilerplate for structured output
- Better error messages
- Future-proof as Google updates the API

---

## Decision 3: Gemini 2.0 Flash over 1.5 Pro

**Chosen**: `gemini-2.0-flash`  
**Rejected**: `gemini-1.5-pro`, `gemini-1.5-flash`

**Rationale**:
- 2.0 Flash is the latest production model as of May 2026
- ~2x faster than 1.5 Pro for structured JSON tasks
- Cost: significantly cheaper per million tokens
- Quality sufficient for supply chain analysis task
- Falls back to `gemini-1.5-flash` if 2.0 unavailable

---

## Decision 4: In-Memory State over Database

**Chosen**: Python dict in-memory state  
**Rejected**: SQLite, Redis, PostgreSQL

**Rationale**:
- Hackathon demo — no persistence needed across restarts
- Zero setup complexity
- Instant reset by restarting uvicorn
- The action chain state only needs to last for one demo session (~5 minutes)
- Dict is thread-safe for single-process uvicorn

---

## Decision 5: Single Gemini Call over Multiple Specialized Calls

**Chosen**: One combined call with all 5 sources  
**Rejected**: 5 separate extraction calls + 1 synthesis call

**Rationale**:
- Fewer API calls = lower latency for demo
- Gemini 2.0 Flash has 1M token context — all 5 sources fit easily (<5000 tokens)
- Single call means single point of failure (simpler error handling)
- The unified prompt produces better cross-source contradiction detection

---

## Decision 6: Step 2 Failure Strategy

**Approach**: Backend tracks `_step2_attempts` counter in module-level dict  
**Trigger**: First call to `/api/execute-step` with `step_number=2` returns `failed`  
**Recovery**: Second call returns `completed`  
**Frontend**: Flutter reads `failed` status, shows FAILED state for 3 seconds, auto-retries

**Why**: Demonstrates autonomous recovery without human intervention. The failure is intentional but realistic — "Supplier API timeout" is a common real-world failure mode.

---

## Decision 7: CORS Configuration

**Approach**: Allow all origins (`*`) in development  
**Rationale**: Flutter Android emulator calls from `10.0.2.2` which would otherwise be CORS-blocked. In production, this would be locked to the app's specific domain.

---

## Decision 8: Pandas for CSV Loading

**Chosen**: `pandas`  
**Rejected**: `csv` stdlib

**Rationale**:
- Richer data representation (DataFrame → dict → JSON)
- Already in requirements (used by many FastAPI projects)
- Makes it easy to compute derived stats (days old, etc.)
- More impressive for hackathon reviewers

---

## Decision 9: Fallback Mock Response

**Approach**: `gemini_client.py` has a `FALLBACK_RESPONSE` constant with hardcoded valid JSON  
**Trigger**: Any exception from Gemini API (network error, quota exceeded, invalid response)  
**Visibility**: Flutter shows a small "⚠ Demo Mode" badge when fallback is used

**Rationale**: The app must never crash during the demo. Gemini API can be unreliable under load. The fallback ensures the full flow is always demonstrable.

---

## Decision 10: Endpoint Design

| Endpoint | Method | Why |
|----------|--------|-----|
| `/api/analyze` | POST | Triggers analysis, has side effects (Gemini call) |
| `/api/execute-step` | POST | Triggers execution, has side effects (state mutation) |
| `/api/outcome` | GET | Pure read, idempotent |

RESTful conventions followed. No WebSockets (would add complexity for marginal benefit in a demo).

---

*Last updated: 2026-05-20T15:31:00+05:00*
