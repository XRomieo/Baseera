# Gemini Prompt Design
## Baseera — AISeekho 2026
### Timestamp: 2026-05-20T15:31:00+05:00

---

## Overview

The Gemini prompt is the heart of Baseera. It converts raw multi-source data into structured intelligence. This document explains every design decision.

---

## Prompt Architecture

The prompt uses a two-layer approach:
1. **System Instruction**: Defines the agent's role and constraints
2. **User Content**: Injects all 5 data sources + the exact output schema

### Why Not Few-Shot Examples?
Few-shot examples would consume ~1500 tokens that aren't needed. Gemini 2.0 Flash follows schema instructions reliably without them. The explicit JSON schema in the prompt is sufficient.

---

## System Instruction (Full Text)

```
You are an autonomous business intelligence agent for a Pakistani retail supply chain.
Your task is to analyze multiple data sources simultaneously, detect contradictions,
assess source credibility, and generate an actionable response plan.

Rules:
- Respond ONLY with valid JSON. No markdown, no explanation, no preamble, no postamble.
- Follow the exact output schema provided.
- Assess credibility based on: recency, specificity, source type, and consistency.
- Contradictions must identify both conflicting sources and declare a credibility winner.
- The action chain must have EXACTLY 4 steps.
- Monetary values in PKR.
- All status fields must be "pending" in your response (execution happens separately).
```

### Design Decisions in System Instruction:

**"Respond ONLY with valid JSON"** — The most critical instruction. Without it, Gemini wraps output in ```json ``` markdown blocks which break JSON parsing.

**"No markdown, no explanation, no preamble"** — Gemini tends to add "Here is my analysis:" before JSON. This triple-explicit instruction prevents it.

**"Assess credibility based on: recency, specificity, source type"** — Gives Gemini a framework rather than asking it to invent one. This produces consistent credibility assessments.

**"Exactly 4 steps"** — Without this, Gemini might return 3 or 5 steps. Explicit count is necessary.

**"All status fields must be pending"** — Prevents Gemini from pre-executing steps in the response.

---

## User Content Template

```
DATA SOURCES:

[SOURCE 1: warehouse_stock.csv]
{csv_content}

[SOURCE 2: supplier_email.json]
{supplier_email_content}

[SOURCE 3: sales_dashboard.json]
{sales_dashboard_content}

[SOURCE 4: customer_complaints.json]
{customer_complaints_content}

[SOURCE 5: market_news_feed.json]
{market_news_content}

---
OUTPUT SCHEMA (respond with exactly this structure):
{
  "sources_summary": [
    {"source": "string", "key_insight": "string", "credibility": "HIGH|MEDIUM|LOW|STALE", "recency": "string"}
  ],
  "key_insights": ["string"],
  "contradictions": [
    {
      "source_a": "string",
      "source_b": "string",
      "conflict": "string",
      "resolution": "string",
      "credibility_winner": "string"
    }
  ],
  "action_chain": [
    {"step": 1, "action": "string", "status": "pending", "constraint": "string", "rationale": "string"}
  ],
  "before_state": {
    "stockout_risk_pct": 87,
    "supplier_status": "string",
    "customer_notifications_sent": 0,
    "inventory_units": 1200,
    "data_confidence": "LOW"
  },
  "after_state": {
    "stockout_risk_pct": 12,
    "supplier_status": "string",
    "customer_notifications_sent": 847,
    "inventory_units_expected": 1200,
    "data_confidence": "HIGH"
  },
  "agent_trace": ["string"]
}
```

---

## Contradiction Detection Design

The prompt relies on Gemini's reasoning to detect:

1. **Numerical Contradiction**: warehouse_stock = 1200 units vs. reality (540 sold in 3 days → should be ~660, but complaints show 0)
2. **Temporal Credibility**: warehouse CSV is 3 days old; complaints are from last 24 hours
3. **Corroboration Chain**: supplier_email + market_news corroborate the delay; sales_dashboard + complaints corroborate the stockout

Expected Gemini reasoning:
- warehouse_stock.csv credibility = STALE (3 days old)
- customer_complaints.json credibility = HIGH (real-time, 47 data points)
- Winner: customer_complaints.json
- Resolution: Run emergency audit to establish true stock level

---

## JSON Parsing Strategy

```python
response_text = response.text.strip()
# Remove potential markdown wrapping
if response_text.startswith("```"):
    response_text = response_text.split("```")[1]
    if response_text.startswith("json"):
        response_text = response_text[4:]
parsed = json.loads(response_text)
```

This handles the three most common Gemini output formats:
1. Raw JSON (ideal)
2. ```json ... ``` wrapped (common)
3. ``` ... ``` wrapped (less common)

---

## Token Budget

| Component | Estimated Tokens |
|-----------|-----------------|
| System instruction | ~150 |
| Source 1 (CSV) | ~400 |
| Source 2 (email JSON) | ~300 |
| Source 3 (sales JSON) | ~500 |
| Source 4 (complaints JSON) | ~600 |
| Source 5 (news JSON) | ~400 |
| Output schema | ~350 |
| **Total Input** | **~2,700** |
| Expected Output | ~800 |
| **Total** | **~3,500 tokens** |

Cost at Gemini 2.0 Flash pricing (~$0.075/1M input, ~$0.30/1M output):
- Input: ~$0.0002
- Output: ~$0.00024
- **Per session: ~$0.0004 ≈ PKR 0.11**

---

## Fallback Strategy

If Gemini API fails for any reason:
1. Log the error
2. Return `FALLBACK_RESPONSE` dict (hardcoded valid JSON)
3. Set `is_fallback: true` flag in the response
4. Flutter displays "⚠ Demo Mode" indicator

The fallback matches the exact schema Gemini would return, so the app flow continues normally.

---

*Last updated: 2026-05-20T15:31:00+05:00*
