# Troubleshooting Guide
## Baseera — AISeekho 2026

---

## Backend Issues

### `pydantic-core` fails to install on Python 3.14
**Error:** `the configured Python interpreter version (3.14) is newer than PyO3's maximum supported version (3.13)`

**Fix:**
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
Newer pydantic versions (2.13+) ship pre-built Python 3.14 wheels — may resolve automatically.

---

### `ModuleNotFoundError: No module named 'google.generativeai'`
```powershell
pip install google-generativeai --upgrade
```

---

### Backend starts but Gemini call fails
Check `backend/.env`:
```
GEMINI_API_KEY=AIzaSy...
```
App still works via hardcoded fallback. A "Demo Mode" badge appears in the UI.

---

### `uvicorn: command not found`
```powershell
python -m uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

---

### Render free-tier cold start (~30 s)
First request after 15 min idle takes ~30–60 s while the dyno wakes.

**Fix:** UptimeRobot → New Monitor → HTTPS → `https://<your-app>.onrender.com/api/health` → 5-min interval. Free forever, keeps backend warm.

---

### Render deploy: `404 on every endpoint`
Wrong Root Directory in Render settings. Must be `backend`, not repo root.

### Render deploy: `ModuleNotFoundError: agents`
Same cause — Root Directory is repo root, so Python can't find `agents/`. Set Root Directory = `backend`.

### Render logs show `GEMINI_API_KEY: ✗ NOT SET`
Env var typo or not saved. Re-enter in Render dashboard → Environment tab → Save. Service auto-redeploys.

---

## Flutter Issues

### Flutter not in PATH
```powershell
D:\flutter\bin\flutter.bat pub get
D:\flutter\bin\flutter.bat run
```
Or add `D:\flutter\bin` to system PATH permanently.

---

### App shows "Connection refused" / "Network error" in debug
1. Backend must be running: `python -m uvicorn main:app --reload --host 0.0.0.0 --port 8000`
2. Emulator URL `http://10.0.2.2:8000` is auto-selected by `kDebugMode`. No code change needed.
3. **Physical device in debug:** swap `_debugUrl` in [mobile/lib/services/api_service.dart](../mobile/lib/services/api_service.dart) to your PC's LAN IP. Find via `ipconfig` → IPv4 address.

---

### Release APK can't reach backend
1. `mobile/.env` exists? Check `BASEERA_API_URL` is set.
2. URL is HTTPS (Render gives HTTPS by default)? Android blocks plain HTTP in release builds without `usesCleartextTraffic`.
3. Backend `/api/health` responds 200 over public internet?
   ```powershell
   curl https://your-app.onrender.com/api/health
   ```
4. Rebuild: `flutter clean && flutter build apk --release`. APK caches the old URL otherwise.

---

### App boots fine but stuck on splash forever
`dotenv.load` silently failing on missing `.env`.
- Confirm `mobile/.env` exists.
- Confirm `.env` is declared in `pubspec.yaml` under `flutter.assets:`.
- Run `flutter clean && flutter pub get && flutter run`.

---

### Native splash still shows old logo / wrong colour after redesign
Android caches splash drawable aggressively. Hot reload won't update it.

**Fix:**
```powershell
adb uninstall com.krevonstudios.baseera
flutter clean
flutter run
```
Or long-press app icon on emulator → Uninstall → run again.

---

### White flash before splash on Android 12+
`values-v31/styles.xml` `LaunchTheme` parent was `Theme.Light.NoTitleBar`. Already fixed to `Theme.Black.NoTitleBar` + explicit `windowSplashScreenBackground=#0A0A12`. If it returns, re-check the styles.xml override.

---

### Action Chain screen lags / app crashes ("Skipped N frames")
Performance regression — usually caused by:
- `AnimatedBuilder` wrapping subtrees with animated `BoxShadow.blurRadius` (blur is GPU-expensive every frame). Use static shadow.
- Nested `IntrinsicHeight` widgets in scrollable lists. Use `Stack` + `Positioned` for left-accent stripes instead.
- A `repeat()` AnimationController driving full-subtree rebuilds (not just compositor transforms).

Profile: `flutter run --profile` for real frame timings. Debug mode is ~10× slower than release on emulators.

---

### "A borderRadius can only be given on borders with uniform colors"
`BoxDecoration(border: Border(left: c1, top: c2, ...), borderRadius: ...)` is illegal in Flutter — non-uniform borders can't be rounded.

**Fix:** drop `border:` from the decoration, wrap in `ClipRRect`, add the colored accent via a separate `Stack` + `Positioned` strip or a single `Border.all` plus an inner colored stripe.

---

### PDF symbols render as boxes / `Unable to find a font to draw "—"`
Default `pdf` package fonts (Helvetica) lack Unicode coverage.

**Fix already applied** in [outcome_screen.dart](../mobile/lib/screens/outcome_screen.dart):
```dart
final outfitRegular = await PdfGoogleFonts.outfitRegular();
final outfitBold    = await PdfGoogleFonts.outfitBold();
final pdf = pw.Document(
  theme: pw.ThemeData.withFont(base: outfitRegular, bold: outfitBold),
);
```
Requires `printing: ^5.14.3` in pubspec.yaml.

---

### Kotlin "Could not close incremental caches" stack trace during `flutter run`
Multiple Kotlin plugins (`share_plus` + `printing`) share daemon caches → corruption.

**Fix already applied** in [android/gradle.properties](../mobile/android/gradle.properties):
```properties
kotlin.incremental=false
kotlin.daemon.useFallbackStrategy=true
```
If error returns, clear stale caches:
```powershell
Remove-Item -Recurse -Force "mobile\build\share_plus\kotlin"
Remove-Item -Recurse -Force "mobile\build\printing\kotlin"
flutter clean
```

---

### AGP / Kotlin deprecation warnings during build
```
Warning: Flutter support for your project's Android Gradle Plugin version (8.7.3) will soon be dropped.
WARNING: Your app uses the following plugins that apply Kotlin Gradle Plugin (KGP): share_plus
```
Warnings only — build still succeeds. Future Flutter deprecations, not current errors. Safe to ignore for the hackathon.

---

### `flutter doctor` shows Android toolchain errors
- Android Studio → SDK Manager → SDK Tools → check **Android SDK Command-line Tools**
- Set `ANDROID_HOME` env var to your SDK path (e.g. `D:\Android\Sdk`)

---

### Android emulator not detected
1. Android Studio → Device Manager
2. Create a Pixel 6 emulator with API 33+
3. Start emulator, then `flutter run`

---

## Common Runtime Issues

### App shows "Demo Mode" badge
Gemini API call failed — app fell back to hardcoded response. Full demo flow still works. Check API key or network.

### Step 2 doesn't show FAILED state
Backend's `_step2_retry_count` counter already incremented. Restart uvicorn to reset state.

### Animation feels slow
2-second delays between steps are intentional for demo visibility. To speed up, edit [backend/agents/action_executor.py](../backend/agents/action_executor.py):
```python
await asyncio.sleep(0.5)  # was 2
```

### Stockout risk bar shows wrong colours
Already fixed — bar fill colour = row accent (red for "Before", green for "After"). If it regresses, check [outcome_screen.dart](../mobile/lib/screens/outcome_screen.dart) `_riskRow` — should use `accent` parameter, not a fixed red→green gradient.

---

## Asset / Icon Issues

### Launcher icon clipped on home-screen launcher
Adaptive icon foreground extends past safe zone.

**Fix:** regenerate `assets/icon/app_icon_foreground.png` with the logo at ~50–53 % of the 1024² canvas (transparent surround). Then:
```powershell
cd mobile
dart run flutter_launcher_icons
```

### Launcher icon background colour wrong
Edit `pubspec.yaml`:
```yaml
flutter_launcher_icons:
  adaptive_icon_background: "#1A1035"   # change this
```
Then `dart run flutter_launcher_icons`.

For legacy (pre-Android 8) icons, the background colour is baked into `assets/icon/app_icon.png` itself — regenerate that PNG with the desired solid fill, then re-run launcher_icons.

---

## Git / Repo Hygiene

### Accidentally committed `.env`
```powershell
git rm --cached backend/.env mobile/.env
git commit -m "Remove tracked .env files"
```
Both `.env` files are in `.gitignore` — they should never have been tracked. After removal, rotate any leaked keys.

### `.env.example` not committed
That's the template. Always commit `.env.example`. Only the real `.env` is gitignored.

---

*Last updated: 2026-05-21*
