"""
agents/action_executor.py
Simulates executing action chain steps with realistic delays.
Step 2 intentionally fails on the first attempt to demonstrate failure recovery.
"""

import asyncio
import time
import logging
from typing import Optional

logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# In-memory execution state (resets on server restart)
# ---------------------------------------------------------------------------

_execution_state: dict = {}
_step2_retry_count: int = 0
_execution_start_time: Optional[float] = None
_step_timings: dict = {}
_outcome_data: Optional[dict] = None


def reset_state() -> None:
    """Reset all execution state — called on server startup and when /api/analyze is called."""
    global _execution_state, _step2_retry_count, _execution_start_time, _step_timings, _outcome_data
    
    _execution_state = {
        1: {
            "step": 1,
            "action": "Conduct emergency physical stock audit at Warehouse-A Shelf-12 for Basmati Rice 5kg",
            "status": "pending",
            "constraint": "Must be completed within 2 hours",
            "attempts": 0,
            "error": None,
            "completion_note": None,
            "started_at": None,
            "completed_at": None,
            "latency_ms": None,
        },
        2: {
            "step": 2,
            "action": "Contact Ahmed Traders and activate emergency procurement from alternative supplier",
            "status": "pending",
            "constraint": "Emergency order budget: PKR 500,000 | Place within 4 hours",
            "attempts": 0,
            "error": None,
            "completion_note": None,
            "started_at": None,
            "completed_at": None,
            "latency_ms": None,
        },
        3: {
            "step": 3,
            "action": "Update website and app to show accurate stock status and notify 847 affected customers",
            "status": "pending",
            "constraint": "Customer notifications within 4 hours",
            "attempts": 0,
            "error": None,
            "completion_note": None,
            "started_at": None,
            "completed_at": None,
            "latency_ms": None,
        },
        4: {
            "step": 4,
            "action": "Activate 24-hour automated inventory monitoring for all fast-moving staples",
            "status": "pending",
            "constraint": "Monitor every 30 minutes | Alert below 3-day buffer",
            "attempts": 0,
            "error": None,
            "completion_note": None,
            "started_at": None,
            "completed_at": None,
            "latency_ms": None,
        },
    }
    _step2_retry_count = 0
    _execution_start_time = None
    _step_timings = {}
    _outcome_data = None
    logger.info("Action executor state reset")


def update_steps_from_analysis(action_chain: list) -> None:
    """Update step actions from Gemini analysis result."""
    for step_data in action_chain:
        step_num = step_data.get("step")
        if step_num and step_num in _execution_state:
            _execution_state[step_num]["action"] = step_data.get("action", _execution_state[step_num]["action"])
            _execution_state[step_num]["constraint"] = step_data.get("constraint", _execution_state[step_num]["constraint"])


async def execute_step(step_number: int) -> dict:
    """
    Simulate executing an action step.
    
    - All steps: 2-second processing delay
    - Step 2, first attempt: returns 'failed' with Supplier API timeout error
    - Step 2, second attempt: returns 'completed' with email fallback note
    - All other steps: always return 'completed' on first attempt
    
    Returns:
        dict with step execution result
    """
    global _step2_retry_count, _execution_start_time
    
    if step_number not in _execution_state:
        return {"error": f"Step {step_number} does not exist"}
    
    if _execution_start_time is None:
        _execution_start_time = time.time()
    
    step = _execution_state[step_number]
    step["status"] = "running"
    step["attempts"] += 1
    step["started_at"] = time.time()
    
    logger.info(f"Executing step {step_number} (attempt {step['attempts']})")
    
    # Simulate processing time
    await asyncio.sleep(2)
    
    end_time = time.time()
    step["latency_ms"] = int((end_time - step["started_at"]) * 1000)
    
    # -----------------------------------------------------------------------
    # Step 2: Intentional first-attempt failure for demo
    # -----------------------------------------------------------------------
    if step_number == 2:
        if _step2_retry_count == 0:
            # First attempt → FAIL
            _step2_retry_count += 1
            step["status"] = "failed"
            step["error"] = "Supplier API timeout — could not reach Ahmed Traders procurement portal (connection timed out after 30s)"
            logger.warning(f"Step 2 failed on attempt 1 (intentional demo failure)")
            
            return {
                "step": step_number,
                "status": "failed",
                "error": step["error"],
                "attempts": step["attempts"],
                "latency_ms": step["latency_ms"],
                "should_retry": True,
                "retry_after_ms": 3000,
            }
        else:
            # Second attempt → SUCCESS via email fallback
            step["status"] = "completed"
            step["error"] = None
            step["completion_note"] = "Completed via email fallback channel — procurement team notified, alternative supplier (Karachi Wholesale Distributors) contacted"
            step["completed_at"] = end_time
            logger.info(f"Step 2 completed on attempt 2 (email fallback)")
    else:
        # All other steps succeed on first attempt
        step["status"] = "completed"
        step["completed_at"] = end_time
        
        # Step-specific completion notes
        notes = {
            1: "Physical audit complete — actual stock confirmed at 47 units (not 1,200). Warehouse system updated.",
            3: "Website updated. SMS notifications sent to 847 customers with revised delivery estimates.",
            4: "Automated monitoring active — checking every 30 minutes. Alert thresholds set at 540-unit buffer (3-day supply).",
        }
        step["completion_note"] = notes.get(step_number)
    
    _step_timings[step_number] = step["latency_ms"]
    
    return {
        "step": step_number,
        "status": step["status"],
        "attempts": step["attempts"],
        "latency_ms": step["latency_ms"],
        "completion_note": step.get("completion_note"),
    }


def get_current_state() -> dict:
    """Return the current execution state of all steps."""
    return {
        "steps": list(_execution_state.values()),
        "step_timings": _step_timings,
    }


def get_outcome() -> dict:
    """
    Return the before/after outcome comparison with computed metrics.
    """
    completed_steps = sum(1 for s in _execution_state.values() if s["status"] == "completed")
    avg_latency = (sum(_step_timings.values()) / len(_step_timings)) if _step_timings else 0
    
    return {
        "before_state": {
            "stockout_risk_pct": 87,
            "supplier_status": "Delivery delayed 5 days — no alternative",
            "customer_notifications_sent": 0,
            "inventory_units": 1200,
            "data_confidence": "LOW",
            "open_complaints": 47,
            "warehouse_data_age": "3 days (stale)",
            "alternative_supplier": "None",
        },
        "after_state": {
            "stockout_risk_pct": 12,
            "supplier_status": "Emergency order placed — Karachi Wholesale Distributors activated",
            "customer_notifications_sent": 847,
            "inventory_units": 47,
            "data_confidence": "HIGH",
            "open_complaints": 0,
            "warehouse_data_age": "< 2 hours (fresh audit)",
            "alternative_supplier": "Karachi Wholesale Distributors (800 units, ETA May 22)",
        },
        "metrics": {
            "actions_completed": completed_steps,
            "actions_total": 4,
            "cost_incurred_pkr": 12500,
            "avg_step_latency_ms": int(avg_latency),
            "total_execution_time_ms": int((time.time() - _execution_start_time) * 1000) if _execution_start_time else 0,
            "step_2_retried": _step2_retry_count > 1 or (_step2_retry_count == 1 and _execution_state[2]["status"] == "completed"),
            "revenue_at_risk_pkr_daily": 87050,
            "estimated_revenue_saved_pkr": 261150,
        },
        "step_details": list(_execution_state.values()),
    }
