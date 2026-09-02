# Improve dashboard and PDF action

- Renamed the home app bar to `Dashboard` and added meter search across names,
  types, numbers, locations, units, and current values.
- Added visible sorting by last edit, name, or meter type and shows the latest
  edit date on every meter card.
- Replaced the terse history `PDF` link with a full-width, explained
  `Verlauf als PDF erstellen` action.
- Added immediate PDF-generation feedback through disabled action state,
  progress text, a spinner, and a progress bar.
- Added widget coverage for dashboard filtering, sorting, edit dates, the PDF
  explanation, and its loading state.
