import 'package:universal_io/io.dart';

import '../../../core/files/meter_photo_repository.dart';
import '../../../core/integrity/integrity_service.dart';
import '../../../core/ocr/meter_ocr_repository.dart';
import '../../../core/reminders/local_notification_reminder_repository.dart';
import '../../../core/utils/id_generator.dart';
import '../../evidence/domain/evidence_export.dart';
import '../domain/meter.dart';
import '../domain/meter_reading.dart';
import '../domain/meter_repositories.dart';
import '../domain/reading_value.dart';

class MeterService {
  const MeterService({
    required this.meters,
    required this.readings,
    required this.exports,
    required this.photos,
    required this.reminders,
  });

  final MeterRepository meters;
  final MeterReadingRepository readings;
  final EvidenceExportRepository exports;
  final MeterPhotoCaptureRepository photos;
  final MeterReminderRepository reminders;

  Future<Meter> create({
    required String label,
    required MeterType type,
    required String unit,
    required String meterNumber,
    required String location,
    ReadingReminderSchedule? reminder,
  }) async {
    final now = DateTime.now().toUtc();
    final meter = Meter(
      id: newLocalId('meter'),
      label: label.trim(),
      type: type,
      unit: unit.trim(),
      meterNumber: meterNumber.trim(),
      location: location.trim(),
      createdAt: now,
      updatedAt: now,
      reminder: reminder,
    );
    await meters.save(meter);
    await reminders.schedule(meter);
    return meter;
  }

  Future<void> update(Meter meter) async {
    final updated = meter.copyWith(updatedAt: DateTime.now().toUtc());
    await meters.save(updated);
    await reminders.schedule(updated);
  }

  Future<void> delete(String meterId) async {
    final meterReadings = await readings.loadForMeter(meterId);
    final evidenceExports = await exports.loadForMeter(meterId);
    for (final reading in meterReadings) {
      for (final path in reading.allPhotoPaths) {
        await photos.delete(path);
      }
      await readings.delete(reading.id);
    }
    for (final export in evidenceExports) {
      final file = File(export.filePath);
      if (await file.exists()) {
        await file.delete();
      }
      await exports.delete(export.id);
    }
    await reminders.cancel(meterId);
    await meters.delete(meterId);
  }
}

class MeterReadingService {
  const MeterReadingService({
    required this.readings,
    required this.photos,
    this.integrity = const IntegrityService(),
  });

  final MeterReadingRepository readings;
  final MeterPhotoCaptureRepository photos;
  final IntegrityService integrity;

  Future<MeterReading> create({
    required Meter meter,
    required StoredMeterPhoto photo,
    required MeterOcrResult ocr,
    required ReadingValue value,
    required String selectedCandidate,
    required DateTime capturedAt,
    required String note,
    LowerReadingReason? lowerReadingReason,
  }) async {
    final now = DateTime.now().toUtc();
    var reading = MeterReading(
      id: newLocalId('reading'),
      meterId: meter.id,
      meter: MeterSnapshot.fromMeter(meter),
      value: value,
      capturedAt: capturedAt.toUtc(),
      timezoneOffsetMinutes: capturedAt.timeZoneOffset.inMinutes,
      storedAt: now,
      updatedAt: now,
      source: photo.source,
      photoPath: photo.path,
      photoSha256: photo.sha256,
      ocrRawText: ocr.rawText,
      ocrCandidate: selectedCandidate,
      ocrConfidence: ocr.confidence,
      photoAddedAt: photo.capturedAt.toUtc(),
      lowerReadingReason: lowerReadingReason,
      note: note.trim(),
      manifestSha256: '',
    );
    reading = reading.copyWith(
      manifestSha256: await integrity.readingManifestHash(reading),
    );
    await readings.save(reading);
    return reading;
  }

  Future<MeterReading> update({
    required MeterReading existing,
    required ReadingValue value,
    required DateTime capturedAt,
    required String note,
    required String reason,
    LowerReadingReason? lowerReadingReason,
    StoredMeterPhoto? replacementPhoto,
    MeterOcrResult? replacementOcr,
    String replacementCandidate = '',
  }) async {
    if ((replacementPhoto == null) != (replacementOcr == null)) {
      throw ArgumentError(
        'Ersatzfoto und OCR-Ergebnis müssen gemeinsam angegeben werden.',
      );
    }
    final changedAt = DateTime.now().toUtc();
    final changes = <String, ReadingChange>{};
    if (existing.value.displayText != value.displayText ||
        existing.value.compareTo(value) != 0) {
      changes['Zählerstand'] = ReadingChange(
        before: existing.value.displayText,
        after: value.displayText,
      );
    }
    if (existing.capturedAt.toLocal() != capturedAt) {
      changes['Zeitpunkt der Ablesung'] = ReadingChange(
        before: existing.capturedAt.toLocal().toIso8601String(),
        after: capturedAt.toIso8601String(),
      );
    }
    if (existing.note != note.trim()) {
      changes['Notiz'] = ReadingChange(
        before: existing.note,
        after: note.trim(),
      );
    }
    if (replacementPhoto != null && replacementOcr != null) {
      changes['Foto SHA-256'] = ReadingChange(
        before: existing.photoSha256,
        after: replacementPhoto.sha256,
      );
      if (existing.source != replacementPhoto.source) {
        changes['Fotoquelle'] = ReadingChange(
          before: existing.source.label,
          after: replacementPhoto.source.label,
        );
      }
      if (existing.ocrCandidate != replacementCandidate) {
        changes['OCR-Kandidat'] = ReadingChange(
          before: existing.ocrCandidate,
          after: replacementCandidate,
        );
      }
    }
    if (changes.isEmpty) {
      return existing;
    }

    final archivedPhotos = replacementPhoto == null
        ? existing.photoHistory
        : [
            ...existing.photoHistory,
            ReadingPhotoVersion(
              id: newLocalId('photo_version'),
              path: existing.photoPath,
              sha256: existing.photoSha256,
              source: existing.source,
              addedAt: existing.effectivePhotoAddedAt,
              ocrRawText: existing.ocrRawText,
              ocrCandidate: existing.ocrCandidate,
              ocrConfidence: existing.ocrConfidence,
            ),
          ];
    var updated = existing.copyWith(
      value: value,
      capturedAt: capturedAt.toUtc(),
      timezoneOffsetMinutes: capturedAt.timeZoneOffset.inMinutes,
      updatedAt: changedAt,
      source: replacementPhoto?.source,
      photoPath: replacementPhoto?.path,
      photoSha256: replacementPhoto?.sha256,
      ocrRawText: replacementOcr?.rawText,
      ocrCandidate: replacementPhoto == null ? null : replacementCandidate,
      ocrConfidence: replacementOcr?.confidence,
      photoAddedAt: replacementPhoto == null ? null : changedAt,
      photoHistory: archivedPhotos,
      note: note.trim(),
      lowerReadingReason: lowerReadingReason,
      clearLowerReadingReason: lowerReadingReason == null,
      manifestSha256: '',
    );
    updated = updated.copyWith(
      manifestSha256: await integrity.readingManifestHash(updated),
    );
    await readings.updateWithRevision(
      updated,
      ReadingRevision(
        id: newLocalId('revision'),
        readingId: existing.id,
        changedAt: changedAt,
        reason: reason.trim(),
        changes: changes,
      ),
    );
    return updated;
  }

  Future<void> delete(MeterReading reading) async {
    for (final path in reading.allPhotoPaths) {
      await photos.delete(path);
    }
    await readings.delete(reading.id);
  }

  Future<MeterReading?> previousReading({
    required String meterId,
    required DateTime capturedAt,
    String? excludingId,
  }) async {
    final items = await readings.loadForMeter(meterId);
    final earlier =
        items
            .where(
              (item) =>
                  item.id != excludingId &&
                  item.capturedAt.isBefore(capturedAt),
            )
            .toList()
          ..sort((a, b) => b.capturedAt.compareTo(a.capturedAt));
    return earlier.firstOrNull;
  }
}

class EvidenceVerificationResult {
  const EvidenceVerificationResult({
    required this.sha256,
    required this.status,
    this.record,
  });

  final String sha256;
  final EvidenceVerificationStatus status;
  final EvidenceExportRecord? record;
}

enum EvidenceVerificationStatus { unchanged, changed, unknown }
