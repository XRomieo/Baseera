# Demo Assets

Place screenshots, screen recordings, and demo notes here.

## Suggested Screenshots
1. `home_screen.png` — Home with "Run Analysis" button
2. `sources_loading.png` — Shimmer animation in progress
3. `sources_complete.png` — All 5 sources processed with credibility badges
4. `contradiction_card.png` — Red contradiction warning card
5. `action_chain_step2_failed.png` — Step 2 showing FAILED state
6. `action_chain_step2_retry.png` — Step 2 showing RETRYING state
7. `action_chain_complete.png` — All 4 steps completed
8. `outcome_dashboard.png` — Before/after metrics
9. `stockout_risk_progress.png` — Animated 87% → 12% bar

## Demo Video Outline
1. (0:00) App launch → Home screen
2. (0:05) Tap "Run Analysis" → Shimmer loading
3. (0:15) Sources resolve with credibility badges
4. (0:25) Scroll to see contradiction card
5. (0:30) Tap "Execute Action Chain"
6. (0:35) Steps 1-2 execute, Step 2 fails
7. (0:45) Step 2 auto-retries and succeeds
8. (0:55) Steps 3-4 complete
9. (1:00) Outcome dashboard — animated risk bar
10. (1:10) Scroll agent trace

## Notes
- Record on Android emulator with ADB screencap
- Screen resolution: 1080x2400 (standard)
- Use `adb shell screenrecord /sdcard/demo.mp4` for video
