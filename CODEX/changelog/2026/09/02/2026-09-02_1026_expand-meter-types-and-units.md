# Expand meter types and units

- Added household meter types for electricity feed-in, cold and hot water,
  heat, heating cost allocation, heating oil, and custom meters.
- Replaced free-form unit entry with meter-specific unit choices and sensible
  defaults while retaining compatibility with previously stored custom units.
- Added a post-save message that guides new users to the first reading and made
  reminder scheduling replaceable in widget tests.
- Added focused domain and widget coverage for the expanded creation flow.
