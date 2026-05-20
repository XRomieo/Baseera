# Troubleshooting Guide
## Baseera — AISeekho 2026

---

## Backend Issues

### ❌ `pydantic-core` fails to install on Python 3.14
**Error**: `the configured Python interpreter version (3.14) is newer than PyO3's maximum supported version (3.13)`

**Fix**:
```powershell
# Windows PowerShell
$env:PYO3_USE_ABI3_FORWARD_COMPATIBILITY=1
pip install -r requirements.txt
```
```bash
# Linux/Mac
export PYO3_USE_ABI3_FORWARD_COMPATIBILITY=1
pip install -r requirements.txt
```
Note: Newer pydantic versions (2.13+) include pre-built Python 3.14 wheels so this may resolve automatically.

---

### ❌ `ModuleNotFoundError: No module named 'google.generativeai'`
```powershell
pip install google-generativeai --upgrade
```

---

### ❌ Backend starts but Gemini call fails
Check your `.env` file exists at `backend/.env` with a valid key:
```
GEMINI_API_KEY=AIzaSy...
```
The app **will still work** using the hardcoded fallback response. A "⚠ Demo Mode" badge will appear in the app.

---

### ❌ `uvicorn: command not found`
```powershell
python -m uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

---

## Flutter Issues

### ❌ Flutter not in PATH
Use the full path instead:
```powershell
D:\flutter\bin\flutter.bat pub get
D:\flutter\bin\flutter.bat run
```
Or add `D:\flutter\bin` to your system PATH permanently.

---

### ❌ `Cannot connect to backend` in Flutter app
1. Make sure `uvicorn main:app --reload --host 0.0.0.0 --port 8000` is running in `backend/`
2. If using **Android Emulator**: URL is `http://10.0.2.2:8000` (already set correctly)
3. If using **physical device**: Change URL in `mobile/lib/services/api_service.dart`:
   ```dart
   const String _baseUrl = 'http://YOUR_LAN_IP:8000';
   ```
   Find your LAN IP with: `ipconfig` (look for IPv4 address)

---

### ❌ `flutter run` fails with SDK errors
```powershell
D:\flutter\bin\flutter.bat doctor
D:\flutter\bin\flutter.bat pub get
D:\flutter\bin\flutter.bat run
```

---

### ❌ Android emulator not detected
Make sure Android Studio is installed and you have created an AVD (Android Virtual Device):
1. Open Android Studio → Device Manager
2. Create a Pixel 6 emulator with API 33 or higher
3. Start the emulator, then run `flutter run`

---

## Common Runtime Issues

### App shows "⚠ Demo Mode" badge
This means the Gemini API call failed and the app is using the hardcoded fallback response. The full demo flow still works. Check your API key or network connection.

### Step 2 doesn't show FAILED state
The failure is controlled by the backend's `_step2_retry_count` counter. If the backend was restarted mid-demo, reset by restarting uvicorn.

### Animation feels slow
The 2-second delays between steps are intentional for demo visibility. To speed up, edit `action_executor.py`:
```python
await asyncio.sleep(0.5)  # Change from 2 to 0.5
```

---

*Last updated: 2026-05-20*
