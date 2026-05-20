"""
main.py — Baseera FastAPI Backend
AISeekho 2026 Hackathon | Challenge 1: Autonomous Content-to-Action Agent

Endpoints:
  POST /api/analyze       → Load all 5 sources, call Gemini, return structured JSON
  POST /api/execute-step  → Simulate action step execution (step 2 fails → retries)
  GET  /api/outcome       → Return before/after comparison metrics

Run with: uvicorn main:app --reload
"""

import logging
import os
import time
from contextlib import asynccontextmanager
from typing import Optional

from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

# Load environment variables
load_dotenv()

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s"
)
logger = logging.getLogger(__name__)

# Import agents
from agents import data_loader, gemini_client, action_executor

# ---------------------------------------------------------------------------
# App lifecycle
# ---------------------------------------------------------------------------

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Initialize state on startup."""
    action_executor.reset_state()
    logger.info("Baseera backend started — state initialized")
    logger.info(f"Gemini API Key: {'✓ loaded' if os.getenv('GEMINI_API_KEY') else '✗ NOT SET (will use fallback)'}")
    yield
    logger.info("Baseera backend shutting down")


# ---------------------------------------------------------------------------
# FastAPI App
# ---------------------------------------------------------------------------

app = FastAPI(
    title="Baseera API",
    description="Autonomous Content-to-Action Agent Backend — AISeekho 2026 Hackathon",
    version="1.0.0",
    lifespan=lifespan,
)

# CORS — allow all origins for hackathon demo
# Android emulator uses 10.0.2.2 to reach host machine's localhost
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# In-memory cache for analysis result (avoid re-calling Gemini on every request)
_cached_analysis: Optional[dict] = None


# ---------------------------------------------------------------------------
# Request / Response Models
# ---------------------------------------------------------------------------

class AnalyzeTrigger(BaseModel):
    trigger: str = "run analysis"
    force_refresh: bool = False


class ExecuteStepRequest(BaseModel):
    step_number: int


# ---------------------------------------------------------------------------
# Routes
# ---------------------------------------------------------------------------

@app.get("/")
async def root():
    return {
        "app": "Baseera",
        "version": "1.0.0",
        "hackathon": "AISeekho 2026",
        "challenge": "Challenge 1: Autonomous Content-to-Action Agent",
        "status": "running",
        "endpoints": ["/api/analyze", "/api/execute-step", "/api/outcome"],
    }


@app.post("/api/analyze")
async def analyze(request: AnalyzeTrigger):
    """
    Load all 5 mock data sources, send to Gemini API, return structured analysis.
    
    The response includes:
    - sources_summary: credibility assessment of each source
    - key_insights: top-level intelligence extracted
    - contradictions: detected conflicts between sources
    - action_chain: 4-step prioritized action plan
    - before_state / after_state: outcome prediction
    - agent_trace: step-by-step reasoning
    """
    global _cached_analysis
    
    start_time = time.time()
    
    # Reset execution state for a fresh analysis run
    action_executor.reset_state()
    
    # Use cached result unless force_refresh is requested
    if _cached_analysis and not request.force_refresh:
        logger.info("Returning cached analysis result")
        return {
            **_cached_analysis,
            "cached": True,
            "latency_ms": 0,
        }
    
    logger.info(f"Starting analysis with trigger: '{request.trigger}'")
    
    try:
        # Step 1: Load all 5 data sources
        logger.info("Loading all 5 mock data sources...")
        sources = data_loader.load_all_sources()
        logger.info(f"Loaded {len(sources)} sources: {list(sources.keys())}")
        
        # Step 2: Send to Gemini for analysis
        logger.info("Sending sources to Gemini API...")
        analysis = gemini_client.analyze_sources(sources)
        logger.info(f"Analysis complete. Fallback used: {analysis.get('is_fallback', False)}")
        
        # Step 3: Update action executor with Gemini's action chain
        if "action_chain" in analysis:
            action_executor.update_steps_from_analysis(analysis["action_chain"])
        
        # Cache the result
        _cached_analysis = analysis
        
        latency_ms = int((time.time() - start_time) * 1000)
        
        return {
            **analysis,
            "cached": False,
            "latency_ms": latency_ms,
            "sources_loaded": list(sources.keys()),
        }
    
    except Exception as e:
        logger.error(f"Analysis failed: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Analysis failed: {str(e)}")


@app.post("/api/execute-step")
async def execute_step(request: ExecuteStepRequest):
    """
    Execute an action chain step and return its updated status.
    
    Step 2 intentionally fails on first call (simulates 'Supplier API timeout'),
    then succeeds on second call (uses email fallback channel).
    
    The client should:
    1. Receive 'failed' → display FAILED state for 3 seconds
    2. Auto-retry by calling this endpoint again with step_number=2
    3. Receive 'completed' → show recovery success
    """
    step_number = request.step_number
    
    if step_number < 1 or step_number > 4:
        raise HTTPException(status_code=400, detail="step_number must be between 1 and 4")
    
    logger.info(f"Executing step {step_number}...")
    
    try:
        result = await action_executor.execute_step(step_number)
        current_state = action_executor.get_current_state()
        
        return {
            **result,
            "all_steps": current_state["steps"],
            "step_timings": current_state["step_timings"],
        }
    
    except Exception as e:
        logger.error(f"Step {step_number} execution error: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Step execution failed: {str(e)}")


@app.get("/api/outcome")
async def get_outcome():
    """
    Return the before vs after state comparison with performance metrics.
    
    Includes:
    - before_state: situation before agent intervention
    - after_state: situation after action chain execution
    - metrics: performance stats (cost, latency, actions completed)
    - step_details: full execution history
    """
    outcome = action_executor.get_outcome()
    
    return {
        **outcome,
        "report_generated_at": time.strftime("%Y-%m-%dT%H:%M:%S+05:00"),
        "agent": "Baseera v1.0",
        "hackathon": "AISeekho 2026",
    }


@app.get("/api/health")
async def health_check():
    """Health check endpoint."""
    return {
        "status": "healthy",
        "gemini_key_configured": bool(os.getenv("GEMINI_API_KEY")),
        "timestamp": time.time(),
    }
