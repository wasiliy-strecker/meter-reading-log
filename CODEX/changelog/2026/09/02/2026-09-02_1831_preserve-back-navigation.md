# Preserve back navigation throughout the app

- Kept the existing navigation history after creating a meter or saving a new
  reading so the Android edge-back gesture returns to the previous app area.
- Changed edit and delete completion flows to pop the current screen when it
  was opened from within the app, with safe route fallbacks for direct entry.
- Added widget coverage for system-back navigation through settings and the
  complete meter, capture, reading, and correction flow.

