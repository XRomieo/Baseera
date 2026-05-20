"""
agents/gemini_client.py
Sends all 5 data sources to Gemini API and returns structured JSON analysis.
Uses google.genai (the new SDK) with fallback to google.generativeai (legacy).
Supports Gemini Enterprise Agent Platform keys (AQ. prefix) for the AISeekho 2026 hackathon.
Includes a hardcoded fallback response if the API is unavailable.
"""

import json
import os
import logging
from typing import Any
from dotenv import load_dotenv

# Load .env file from the backend directory
load_dotenv()

logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# Fallback response — used if Gemini API fails (quota, network, etc.)
# ---------------------------------------------------------------------------
FALLBACK_RESPONSE = {
    "is_fallback": True,
    "sources_summary": [
        {
            "source": "warehouse_stock.csv",
            "key_insight": "Warehouse records show 1,200 units of Basmati Rice 5kg as of May 17, 2026. However, this data is 3 days old and does not reflect recent sales or the current stock situation.",
            "credibility": "STALE",
            "recency": "3 days old (2026-05-17)"
        },
        {
            "source": "supplier_email.json",
            "key_insight": "Ahmed Traders has confirmed a 5-day delivery delay for the 800-unit Basmati Rice consignment (Order KR-2026-PR-0892) due to the Punjab transport workers' strike. Revised delivery: May 25, 2026.",
            "credibility": "HIGH",
            "recency": "Today (2026-05-20 09:14 PKT)"
        },
        {
            "source": "sales_dashboard.json",
            "key_insight": "Basmati Rice 5kg has been selling at 180 units/day average over the past 7 days. In the last 3 days alone (since the warehouse count), 542 units have been sold. Adjusted estimated stock is only ~658 units.",
            "credibility": "HIGH",
            "recency": "Real-time (updated daily)"
        },
        {
            "source": "customer_complaints.json",
            "key_insight": "47 customers reported 'out of stock' errors for Basmati Rice 5kg in the last 24 hours — a 20x spike above the 30-day baseline. This strongly indicates actual stock is at or near zero, directly contradicting the warehouse CSV.",
            "credibility": "HIGH",
            "recency": "Last 24 hours (most recent)"
        },
        {
            "source": "market_news_feed.json",
            "key_insight": "The Punjab transport workers' strike is in Day 3, halting freight movement across Gujranwala, Lahore, and Faisalabad corridors. The strike is expected to last until May 23 at earliest. Basmati rice is among the most affected commodities.",
            "credibility": "MEDIUM",
            "recency": "Today (aggregated up to 13:00 PKT)"
        }
    ],
    "key_insights": [
        "Warehouse stock data (1,200 units) is 3 days old and does NOT reflect current reality.",
        "Sales velocity of 180 units/day means ~540 units were sold since the last warehouse count.",
        "Customer complaints (47 in 24hrs, 20x spike) confirm the product is effectively out of stock.",
        "The incoming resupply of 800 units has been delayed by 5 days due to the Punjab transport strike.",
        "Market news independently corroborates the supply disruption, adding credibility to the supplier's delay notice.",
        "Combined risk: current stockout + delayed resupply = critical supply gap of at least 5-7 days."
    ],
    "contradictions": [
        {
            "source_a": "warehouse_stock.csv",
            "source_b": "customer_complaints.json",
            "conflict": "Warehouse records show 1,200 units of Basmati Rice 5kg available. Customer complaints show 47 'out of stock' errors in the last 24 hours, implying actual stock is zero or unavailable.",
            "resolution": "warehouse_stock.csv is 3 days old. In the intervening 3 days, ~542 units were sold per sales dashboard data. The remaining estimated stock (~658 units) appears to be either physically unavailable, damaged, or already allocated, resulting in an effective stockout. Customer complaints data is real-time and more credible.",
            "credibility_winner": "customer_complaints.json"
        },
        {
            "source_a": "warehouse_stock.csv",
            "source_b": "sales_dashboard.json",
            "conflict": "Warehouse CSV claims 1,200 units as of May 17. Sales dashboard shows 542 units sold in the 3 days since that snapshot, suggesting actual stock should be ~658 units. Yet the system is showing out-of-stock errors.",
            "resolution": "The warehouse figure is stale. After accounting for 3 days of sales at 180 units/day, the true physical stock should be approximately 658 units. The out-of-stock errors suggest these remaining units may be reserved, damaged, or inaccessible — the sales dashboard confirms the rate of depletion.",
            "credibility_winner": "sales_dashboard.json"
        }
    ],
    "action_chain": [
        {
            "step": 1,
            "action": "Conduct emergency physical stock audit at Warehouse-A Shelf-12 for Basmati Rice 5kg",
            "status": "pending",
            "constraint": "Audit must complete within 2 hours; 2 staff dispatched; no monetary cost",
            "budget_pkr": 0,
            "deadline": "2 hours",
            "urgency": "HIGH",
            "rate_limit": "None — internal operation",
            "feasibility": "FEASIBLE",
            "rationale": "Contradictions between warehouse CSV and customer complaints require ground-truth verification before any other action can be reliably taken."
        },
        {
            "step": 2,
            "action": "Contact Ahmed Traders and activate emergency procurement from alternative supplier in Karachi",
            "status": "pending",
            "constraint": "Emergency order ceiling PKR 500,000; place within 4 hours; supplier API quota 60 req/hr",
            "budget_pkr": 500000,
            "deadline": "4 hours",
            "urgency": "HIGH",
            "rate_limit": "Supplier API 60 req/hr — within ceiling",
            "feasibility": "FEASIBLE",
            "rationale": "Primary supplier (Ahmed Traders) has confirmed 5-day delay. Alternative suppliers in unaffected regions (Karachi, Sindh) should be contacted immediately to bridge the supply gap."
        },
        {
            "step": 3,
            "action": "Update website and app to show accurate stock status and notify 847 affected customers via SMS/email",
            "status": "pending",
            "constraint": "Notifications dispatched in 4 hours; SMS gateway PKR 1.50/msg = PKR 1,270; rate limit 100 msg/min",
            "budget_pkr": 1270,
            "deadline": "4 hours",
            "urgency": "HIGH",
            "rate_limit": "SMS gateway 100 msg/min — 847 msgs in ~9 min",
            "feasibility": "FEASIBLE",
            "rationale": "47 customers have already complained. Proactive notification to all recent buyers prevents further churn and demonstrates transparency."
        },
        {
            "step": 4,
            "action": "Activate 24-hour automated inventory monitoring for all fast-moving staples",
            "status": "pending",
            "constraint": "Polls every 30 min; alert below 3-day buffer; infra cost PKR 800/mo; ongoing job",
            "budget_pkr": 800,
            "deadline": "Continuous (24/7)",
            "urgency": "MEDIUM",
            "rate_limit": "Internal cron — 48 polls/day",
            "feasibility": "FEASIBLE",
            "rationale": "The root cause was stale warehouse data (3 days old) being used as ground truth. Automated monitoring prevents this from recurring."
        }
    ],
    "before_state": {
        "stockout_risk_pct": 87,
        "supplier_status": "unresponsive - delivery delayed 5 days",
        "customer_notifications_sent": 0,
        "inventory_units": 1200,
        "data_confidence": "LOW",
        "open_complaints": 47,
        "warehouse_data_age_days": 3,
        "alternative_supplier": "none"
    },
    "after_state": {
        "stockout_risk_pct": 12,
        "supplier_status": "emergency order placed - alternative supplier activated",
        "customer_notifications_sent": 847,
        "inventory_units_expected": 1000,
        "data_confidence": "HIGH",
        "open_complaints": 0,
        "warehouse_data_age_hours": 2,
        "alternative_supplier": "Karachi Wholesale Distributors (PKR 1,900/unit)"
    },
    "agent_trace": [
        "Ingested 5 data sources: warehouse_stock.csv, supplier_email.json, sales_dashboard.json, customer_complaints.json, market_news_feed.json",
        "Assessed temporal credibility: warehouse_stock.csv flagged as STALE (3 days old)",
        "Cross-referenced sales velocity (180 units/day x 3 days = 540 units) with warehouse snapshot (1,200 units) => estimated current stock: ~658 units",
        "Detected CRITICAL contradiction: customer complaints show zero-stock conditions despite warehouse showing 1,200 units",
        "Resolved contradiction: customer_complaints.json selected as ground truth (real-time, 47 data points, 20x spike above baseline)",
        "Corroborated: market_news_feed.json confirms Punjab transport strike -- consistent with supplier delay claim",
        "Assessed combined risk: stockout (current) + delayed resupply (5 days) = supply gap of 5-7 days for a 180-unit/day product",
        "Generated 4-step action chain prioritized by urgency: Audit -> Procure -> Notify -> Monitor",
        "Projected outcome: stockout risk 87% -> 12% with action chain execution",
        "Estimated cost of inaction: PKR 87,050 in lost revenue per day (47 lost orders x PKR 1,850)",
        "Action chain generated. Awaiting execution authorization."
    ]
}


def analyze_sources(sources: dict) -> dict:
    """
    Send all source data to Gemini API and return structured JSON analysis.
    Reads GEMINI_API_KEY from environment (loaded from .env by dotenv).
    Falls back to FALLBACK_RESPONSE if no key is set or all API calls fail.
    """
    api_key = os.getenv("GEMINI_API_KEY")

    if not api_key:
        logger.warning("GEMINI_API_KEY not set in .env -- using fallback response")
        logger.warning("Copy backend/.env.example to backend/.env and set your key")
        return FALLBACK_RESPONSE

    logger.info(f"Using API key: {api_key[:8]}... (Gemini Enterprise Platform)")

    # Try new SDK first (supports AQ. enterprise keys)
    try:
        return _call_with_new_sdk(api_key, sources)
    except ImportError:
        logger.info("google.genai not available, trying legacy SDK")
    except Exception as e:
        logger.warning(f"New SDK failed: {e}, trying legacy SDK")

    # Try legacy SDK
    try:
        return _call_with_legacy_sdk(api_key, sources)
    except ImportError:
        logger.warning("No Gemini SDK available -- using fallback")
    except Exception as e:
        logger.error(f"Legacy SDK also failed: {e} -- using fallback")

    return FALLBACK_RESPONSE



def _call_with_new_sdk(api_key: str, sources: dict) -> dict:
    """Use the new google.genai SDK (google-genai package).
    
    Supports both standard Gemini keys and Antigravity Enterprise keys (AQ. prefix).
    The AQ. keys use the Gemini Enterprise Agent Platform endpoint.
    """
    from google import genai
    from google.genai import types

    # AQ. keys are Antigravity/Enterprise platform keys — pass directly as api_key
    # The google.genai SDK handles the AQ. prefix natively
    client = genai.Client(api_key=api_key)
    user_content = _build_user_content(sources)
    system_instruction = _build_system_instruction()

    # Models available on Gemini Enterprise Agent Platform
    # gemini-2.5-flash first (works with AQ. keys), others as fallback
    models_to_try = [
        "gemini-2.5-flash",
        "gemini-2.5-flash-preview-04-17",
        "gemini-2.0-flash",
        "gemini-2.0-flash-lite",
    ]

    for model_name in models_to_try:
        try:
            response = client.models.generate_content(
                model=model_name,
                contents=user_content,
                config=types.GenerateContentConfig(
                    system_instruction=system_instruction,
                    temperature=0.1,
                    max_output_tokens=8192,  # Increased to prevent JSON truncation
                ),
            )
            logger.info(f"✓ Gemini response via new SDK ({model_name})")
            result = _parse_response(response.text)
            result["is_fallback"] = False
            return result
        except json.JSONDecodeError as e:
            logger.warning(f"Model {model_name} returned malformed JSON: {e} -- trying next model")
            continue
        except Exception as e:
            logger.warning(f"Model {model_name} failed: {e}")
            continue

    raise Exception("All models failed with new SDK")



def _call_with_legacy_sdk(api_key: str, sources: dict) -> dict:
    """Use the legacy google.generativeai SDK."""
    import warnings
    with warnings.catch_warnings():
        warnings.simplefilter("ignore")
        import google.generativeai as genai

    genai.configure(api_key=api_key)
    user_content = _build_user_content(sources)

    for model_name in ["gemini-2.5-flash", "gemini-2.0-flash"]:
        try:
            model = genai.GenerativeModel(
                model_name=model_name,
                generation_config=genai.types.GenerationConfig(
                    temperature=0.1,
                    max_output_tokens=8192,
                ),
                system_instruction=_build_system_instruction()
            )
            response = model.generate_content(user_content)
            logger.info(f"Gemini response received via legacy SDK ({model_name})")
            result = _parse_response(response.text)
            result["is_fallback"] = False
            return result
        except json.JSONDecodeError as e:
            logger.warning(f"Model {model_name} returned malformed JSON: {e} -- trying next")
            continue
        except Exception as e:
            logger.warning(f"Model {model_name} failed: {e}")
            continue

    raise Exception("All models failed with legacy SDK")


def _build_system_instruction() -> str:
    return (
        "You are an autonomous business intelligence agent for a Pakistani retail supply chain. "
        "Your task is to analyze multiple data sources simultaneously, detect contradictions, "
        "assess source credibility, and generate an actionable response plan.\n\n"
        "Rules:\n"
        "- Respond ONLY with valid JSON. No markdown, no explanation, no preamble, no postamble.\n"
        "- Follow the exact output schema provided in the user message.\n"
        "- Assess credibility based on: recency, specificity, source type, and consistency with other sources.\n"
        "- Contradictions must identify both conflicting sources and declare a credibility winner.\n"
        "- The action_chain must have EXACTLY 4 steps, numbered 1 through 4.\n"
        "- All action_chain status fields must be set to 'pending' (execution happens separately).\n"
        "- Monetary values should be in PKR.\n"
        "- Every action step MUST include: budget_pkr (integer, 0 if no spend), deadline (string), "
        "urgency (HIGH|MEDIUM|LOW), rate_limit (string describing API/dispatch quota or 'None' if internal), "
        "and feasibility (FEASIBLE|MODIFIED|INFEASIBLE — assess against the budget and rate limit).\n"
        "- The constraint field stays as a 1-line human-readable summary of the structured fields above.\n"
        "- If a step would violate its budget or rate limit, set feasibility to MODIFIED and reduce scope, "
        "or INFEASIBLE and skip — never silently violate a constraint.\n"
        "- Be specific, analytical, and data-driven in your assessments."
    )


def _build_user_content(sources: dict) -> str:
    parts = ["Analyze these 5 data sources from a Pakistani retail supply chain:\n"]

    for i, (source_name, content) in enumerate(sources.items(), 1):
        parts.append(f"[SOURCE {i}: {source_name}]")
        parts.append(content)
        parts.append("")

    schema = json.dumps({
        "sources_summary": [
            {
                "source": "string (filename)",
                "key_insight": "string (2-3 sentences)",
                "credibility": "HIGH|MEDIUM|LOW|STALE",
                "recency": "string (how recent is this data)"
            }
        ],
        "key_insights": ["string (6-8 overall insights across all sources)"],
        "contradictions": [
            {
                "source_a": "string",
                "source_b": "string",
                "conflict": "string (specific contradiction)",
                "resolution": "string (which source is more credible and why)",
                "credibility_winner": "string (more credible source)"
            }
        ],
        "action_chain": [
            {
                "step": 1,
                "action": "string (specific actionable step)",
                "status": "pending",
                "constraint": "string (1-line summary combining budget + deadline + rate limit)",
                "budget_pkr": 0,
                "deadline": "string (e.g. '2 hours', '24 hours', 'Continuous')",
                "urgency": "HIGH|MEDIUM|LOW",
                "rate_limit": "string (API quota / dispatch limit / 'None' if internal)",
                "feasibility": "FEASIBLE|MODIFIED|INFEASIBLE",
                "rationale": "string (why this step, why this priority)"
            }
        ],
        "before_state": {
            "stockout_risk_pct": 87,
            "supplier_status": "string",
            "customer_notifications_sent": 0,
            "inventory_units": 1200,
            "data_confidence": "LOW",
            "open_complaints": 47,
            "warehouse_data_age_days": 3,
            "alternative_supplier": "none"
        },
        "after_state": {
            "stockout_risk_pct": 12,
            "supplier_status": "string",
            "customer_notifications_sent": 847,
            "inventory_units_expected": 1000,
            "data_confidence": "HIGH",
            "open_complaints": 0,
            "warehouse_data_age_hours": 2,
            "alternative_supplier": "string"
        },
        "agent_trace": ["string (step-by-step reasoning, 8-12 items)"]
    }, indent=2)

    parts.append("---")
    parts.append("OUTPUT SCHEMA (respond with exactly this JSON structure, no other text):")
    parts.append(schema)

    return "\n".join(parts)


def _parse_response(response_text: str) -> dict:
    """Parse Gemini response, stripping any markdown code fences."""
    text = response_text.strip()

    # Strip markdown code fences (```json ... ``` or ``` ... ```)
    if text.startswith("```"):
        lines = text.split("\n")
        inner_lines = []
        in_block = False
        for line in lines:
            if line.startswith("```") and not in_block:
                in_block = True
                continue
            elif line.startswith("```") and in_block:
                break
            elif in_block:
                inner_lines.append(line)
        text = "\n".join(inner_lines)

    # Try parsing as-is first
    try:
        return json.loads(text)
    except json.JSONDecodeError:
        pass

    # If truncated, try to find the largest valid JSON prefix by locating the
    # last complete top-level key and closing the object
    # Find the last '}, {' pattern and try up to that point
    logger.warning("JSON parse failed — attempting recovery of truncated response")
    
    # Try finding a recoverable JSON by truncating at the last valid closing brace
    for end_pos in range(len(text) - 1, 0, -1):
        if text[end_pos] == '}':
            try:
                candidate = text[:end_pos + 1]
                return json.loads(candidate)
            except json.JSONDecodeError:
                continue

    raise json.JSONDecodeError("Could not recover valid JSON from response", text, 0)
