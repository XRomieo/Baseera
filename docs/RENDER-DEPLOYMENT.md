# Backend Deployment — Render

Step-by-step guide for deploying the Baseera FastAPI backend to Render so the release APK works on any device with internet.

**Why Render:** free tier, HTTPS by default, auto-deploys from GitHub, no Dockerfile required, picks up FastAPI from `requirements.txt` + start command.

**Cost:** $0 on free tier (with 15 min idle sleep) or $7/mo on Starter for always-on.

---

## Prerequisites

- GitHub account with the Baseera repo pushed
- Render account: https://render.com (free signup with GitHub)
- Gemini API key: https://aistudio.google.com/app/apikey
- Backend code already at `backend/` in the repo
- A payment card on file (Render holds $1 for verification, refundable; **no auto-charge** if free limits exhausted — service just suspends)

---

## Step 1 — Push backend to GitHub

```powershell
git status backend/
git add backend/
git commit -m "Backend ready for Render"
git push origin main
```

Confirm `backend/main.py`, `backend/requirements.txt`, and `backend/agents/` are tracked. Confirm `backend/.env` is **NOT** tracked:

```powershell
git ls-files backend/.env
```
Should return empty. If it shows the file, remove from tracking before continuing:
```powershell
git rm --cached backend/.env
git commit -m "Untrack .env"
git push
```

---

## Step 2 — Create the Web Service

1. Render dashboard → **New** → **Web Service**.
2. Connect GitHub → pick `Baseera` repo.
3. Fill the form:

| Field | Value |
|---|---|
| **Name** | `baseera-api` (becomes part of URL: `baseera-api.onrender.com`) |
| **Language** | `Python 3` |
| **Branch** | `main` |
| **Region** | `Singapore` (closest to Pakistan/MENA judges) |
| **Root Directory** | `backend` ← **critical**, the API lives in a subfolder |
| **Build Command** | `pip install -r requirements.txt` |
| **Start Command** | `uvicorn main:app --host 0.0.0.0 --port $PORT` |
| **Instance Type** | `Free` (upgrade to `Starter` $7/mo later if cold starts hurt) |
| **Health Check Path** | `/api/health` |
| **Auto-Deploy** | `On Commit` ✓ |
| **Pre-Deploy Command** | *(leave empty)* |

4. Scroll to **Environment Variables** → **Add Environment Variable** twice:

| Key | Value |
|---|---|
| `GEMINI_API_KEY` | your real key from Google AI Studio |
| `PYTHON_VERSION` | `3.11.9` |

5. Click **Deploy Web Service**.

---

## Step 3 — Watch the deploy

Dashboard → **Logs** tab. Successful boot looks like:

```
Building...
==> Running build command 'pip install -r requirements.txt'...
... pip install output ...
==> Build successful 🎉
==> Deploying...
==> Running 'uvicorn main:app --host 0.0.0.0 --port $PORT'
==> Your service is live 🎉
==> Available at your primary URL https://baseera-api-XXXX.onrender.com
```

Copy the URL Render shows — that's your `BASEERA_API_URL`.

---

## Step 4 — Smoke test

```powershell
curl https://baseera-api-XXXX.onrender.com/api/health
```

Expected response:
```json
{"status":"healthy","gemini_key_configured":true,"timestamp":1779305626.02}
```

Key fields:
- `status: healthy` → uvicorn running
- `gemini_key_configured: true` → `GEMINI_API_KEY` env var set correctly

If `gemini_key_configured: false`, go back to dashboard → Environment → fix the key → wait for redeploy.

---

## Step 5 — Wire the Flutter app

Edit [mobile/.env](../mobile/.env):

```
BASEERA_API_URL=https://baseera-api-XXXX.onrender.com
```

**No trailing slash.** No quotes around the value.

Build release APK:

```powershell
cd mobile
flutter clean
flutter build apk --release
```

APK lands at `mobile/build/app/outputs/flutter-apk/app-release.apk`. Install on any device with internet — backend is now publicly reachable.

---

## Step 6 — Kill cold starts (recommended)

Free-tier Render sleeps after 15 min idle. Next request takes ~30 s to wake. Two options:

### Option A — UptimeRobot (free, recommended)

1. https://uptimerobot.com → sign up (free)
2. **New Monitor** → type **HTTP(s)**
3. URL: `https://baseera-api-XXXX.onrender.com/api/health`
4. Monitoring Interval: **5 minutes**
5. Save

Backend now stays warm 24/7. Free forever.

### Option B — Upgrade Render plan

Dashboard → service → **Settings** → Instance Type → **Starter** ($7/mo). No sleep, no cold start, more RAM. Worth it for demo day if Wi-Fi reliability matters.

---

## Updating the backend later

Render watches `main` branch. Push → auto-redeploy:

```powershell
git add backend/
git commit -m "Backend update"
git push origin main
```

Dashboard → **Logs** confirms the new deploy.

---

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `502 Bad Gateway` on first request | Service still booting / crashed at startup | Logs tab — usually missing env var or import error |
| `404` on every endpoint | Wrong Root Directory | Must be `backend`, not repo root |
| `ModuleNotFoundError: agents` in logs | Wrong Root Directory (same as above) | Fix in Settings → Build & Deploy |
| Logs show `GEMINI_API_KEY: ✗ NOT SET` | Env var missing or typo'd | Re-enter in Environment tab, wait for redeploy |
| First request takes 30 s | Free-tier cold start | UptimeRobot ping every 5 min, or upgrade to Starter |
| `pydantic-core` build fails | Python version mismatch | Confirm `PYTHON_VERSION=3.11.9` in Environment tab |
| Gemini returns 429 / quota error | Free Gemini tier hit (15 req/min, 1500/day) | Wait, or rotate to a fresh key |
| Mobile app shows "Demo Mode" badge | Backend unreachable from device | Verify `BASEERA_API_URL` in `mobile/.env` is HTTPS and reachable from a browser |

---

## Billing safety check

Render free tier:
- 750 instance-hours/month per workspace
- Sleeps after 15 min idle (counts only running time)
- Service **suspends** when limits hit — does **NOT** auto-charge

To confirm no auto-upgrade:
- Dashboard → **Billing** → check for any "Spend Limit" or "Auto-upgrade" toggle. Disable if present.
- Hackathon usage (a few days, dozens of requests) is well under 750 hrs.

---

## Quick reference card

| Action | Command / Location |
|---|---|
| Backend URL | Render dashboard top of service page |
| Live health check | `curl <URL>/api/health` |
| Trigger redeploy | `git push origin main` |
| View logs | Dashboard → Logs tab |
| Change env var | Dashboard → Environment → edit → Save (auto-redeploys) |
| Pause service | Dashboard → Settings → Suspend |
| Delete service | Dashboard → Settings → Delete Service (bottom) |
| Flutter release APK | `cd mobile && flutter clean && flutter build apk --release` |
| APK location | `mobile/build/app/outputs/flutter-apk/app-release.apk` |

---

*For non-Render hosts (Fly.io, Cloud Run, Railway), see comments inside [mobile/.env.example](../mobile/.env.example).*
