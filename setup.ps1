# Baseera — Quick Start Script
# Run this from the project root: PowerShell -File setup.ps1

Write-Host "╔════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   Baseera — AISeekho 2026 Setup   ║" -ForegroundColor Cyan  
Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# ─── Backend Setup ───────────────────────────────────────────────
Write-Host "📦 Setting up Python backend..." -ForegroundColor Yellow

$backendDir = Join-Path $PSScriptRoot "backend"
Set-Location $backendDir

# Create virtual environment if it doesn't exist
if (-not (Test-Path "venv")) {
    Write-Host "   Creating virtual environment..."
    python -m venv venv
}

# Activate and install (PYO3 compat flag needed for Python 3.14+)
Write-Host "   Installing dependencies (Python 3.14 compat mode)..."
$env:PYO3_USE_ABI3_FORWARD_COMPATIBILITY = "1"
& "venv\Scripts\pip.exe" install -r requirements.txt --quiet

Write-Host "✅ Backend ready!" -ForegroundColor Green
Write-Host ""

# ─── Instructions ────────────────────────────────────────────────
Write-Host "📋 To run the project:" -ForegroundColor Cyan
Write-Host ""
Write-Host "   TERMINAL 1 — Backend:" -ForegroundColor White
Write-Host "   cd backend" -ForegroundColor Gray
Write-Host "   venv\Scripts\activate" -ForegroundColor Gray
Write-Host "   uvicorn main:app --reload --host 0.0.0.0 --port 8000" -ForegroundColor Gray
Write-Host ""
Write-Host "   TERMINAL 2 — Flutter App:" -ForegroundColor White
Write-Host "   cd mobile" -ForegroundColor Gray
Write-Host "   flutter pub get" -ForegroundColor Gray
Write-Host "   flutter run" -ForegroundColor Gray
Write-Host ""
Write-Host "   Backend will be at: http://localhost:8000" -ForegroundColor Gray
Write-Host "   API docs at:        http://localhost:8000/docs" -ForegroundColor Gray
Write-Host ""
Write-Host "🎯 Gemini API Key: Already configured in backend/.env" -ForegroundColor Green
Write-Host ""
