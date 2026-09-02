# Preserve corrected reading photos

- Added camera and gallery photo replacement with on-device OCR to the reading
  correction flow without changing the reading timestamp automatically.
- Preserved every superseded photo as an immutable version with source, added
  time, OCR metadata, and SHA-256 fingerprint in a versioned database schema.
- Added a photo-history viewer, a plain-language SHA-256 explanation, concise
  photo-hash revisions, and complete archived-photo cleanup on deletion.
- Included all photo versions in new evidence PDFs and encrypted backups while
  retaining import compatibility with version 1 backups and legacy readings.
- Added service, persistence, integrity, backup, PDF, and widget coverage for
  photo corrections and version history.
