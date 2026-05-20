# Flutter UI/UX Decisions
## Baseera — AISeekho 2026
### Timestamp: 2026-05-20T15:31:00+05:00

---

## Decision 1: Provider over Riverpod

**Chosen**: `provider`  
**Rejected**: `riverpod`, `bloc`, `getx`

**Rationale**:
- Provider is simpler for a demo app with 4 screens
- Well-understood by Flutter community judges
- Less boilerplate than Riverpod for straightforward state
- Single `AnalysisProvider` can hold all state cleanly

---

## Decision 2: Linear Navigation Flow

**Chosen**: Push navigation (Home → Sources → ActionChain → Outcome)  
**Rejected**: Bottom navigation bar, drawer navigation

**Rationale**:
- Linear flow mirrors the agent's actual workflow: analyze → detect → act → review
- Users can't skip steps (Sources must be analyzed before Action Chain)
- Bottom nav would imply all screens are equally accessible at any time
- Matches the "autonomous agent executing sequentially" narrative

---

## Decision 3: Material 3 Design

**Chosen**: Material 3 (`useMaterial3: true`)  
**Rejected**: Material 2, Cupertino, custom design system

**Rationale**:
- Google hackathon — Material 3 is Google's latest design language
- Dynamic color, expressive components, accessible by default
- Elevation and surface tinting look premium out of the box
- `ColorScheme.fromSeed()` generates a harmonious full palette from the deep blue seed

---

## Decision 4: Outfit Font from Google Fonts

**Chosen**: `Outfit` (Google Fonts)  
**Rejected**: Roboto (default), Inter, Poppins

**Rationale**:
- Outfit is modern, tech-forward, highly legible
- Geometric letterforms suggest "AI" and "analytics" themes
- Variable weight support (300–800) allows fine typography hierarchy
- Available in google_fonts package

---

## Decision 5: Shimmer Animation for Source Cards

**Chosen**: `shimmer` package  
**Rejected**: CircularProgressIndicator, custom FadeTransition

**Rationale**:
- Shimmer effect communicates "loading from multiple sources" intuitively
- Each card shimmers then resolves to content — mirrors sequential processing
- Provides a professional, app-like feel (seen in LinkedIn, Facebook feeds)
- Takes <10 lines of code with the shimmer package

---

## Decision 6: Auto-Progression vs Manual Next Step

**Chosen**: Auto-progression with visual feedback (2-second delay per step)  
**Rejected**: Manual "Next Step" button

**Rationale**:
- "Autonomous" agent should proceed autonomously — no human needed
- The demo is more impressive if it runs itself
- 2-second delay gives judges time to read each step's status before it advances
- A "Pause" option could be added but was deemed unnecessary for the demo

---

## Decision 7: Credibility Badge Design

**Badges**:
- 🟢 HIGH — green chip with checkmark
- 🟡 MEDIUM — amber chip with info icon
- 🔴 LOW — red chip with warning icon
- ⚠️ STALE — dark orange chip with clock icon

**Rationale**:
- Color + icon + text = triple redundancy (accessible for color-blind users)
- Instantly communicates trustworthiness of each data source
- "STALE" is a distinct badge type because staleness is a specific credibility issue different from general uncertainty

---

## Decision 8: Before/After Dashboard Layout

**Layout**: Two-column comparison with colored left/right panels  
**Left**: Before state (red-tinted)  
**Right**: After state (green-tinted)

**Rationale**:
- Side-by-side comparison is the most intuitive way to show delta
- Red/green color coding aligns with universal "bad → good" semantics
- Animated progress bar (stockout risk) provides a dynamic data visualization
- PKR currency formatting shows local context for Pakistani business

---

## Decision 9: Dio over http Package

**Chosen**: `dio`  
**Rejected**: `http` (Flutter stdlib-like), `chopper`

**Rationale**:
- Dio interceptors make adding auth headers easy in the future
- Better timeout configuration (connectTimeout vs receiveTimeout separately)
- Response error handling is more fine-grained
- Dio is the industry standard for Flutter HTTP in 2025+

---

## Decision 10: Android Localhost URL

**Production**: `http://YOUR_SERVER_IP:8000`  
**Development**: `http://10.0.2.2:8000` (Android emulator maps to host machine's localhost)

**Rationale**:
- Android emulator cannot reach `localhost` directly — it uses a special IP
- Physical device testing requires the host machine's LAN IP
- Configurable via a constant in `api_service.dart`

---

## Decision 11: Error Screen Design

**Design**: Full-screen error with icon, message, and "Retry" button  
**Rationale**:
- Never show a blank screen or cryptic error message
- The retry button calls the same API endpoint again
- Friendly error message: "Couldn't connect to Baseera backend. Make sure the server is running."

---

*Last updated: 2026-05-20T15:31:00+05:00*
