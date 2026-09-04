# Show progress while creating a single-reading PDF

- Changed the single-reading PDF action to immediately display `PDF wird
  erstellt …`, a spinner, and an indeterminate progress bar.
- Added a short explanation that the photo and evidence data are being
  processed and exposed it as an accessibility live region.
- Waited for the progress frame before starting PDF generation so expensive
  image and document work cannot hide the initial feedback.
- Added widget coverage with a deliberately pending PDF service.

