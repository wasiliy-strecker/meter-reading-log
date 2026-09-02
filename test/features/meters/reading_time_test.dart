import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meter_reading_log/features/evidence/application/evidence_report_service.dart';
import 'package:meter_reading_log/features/meters/domain/meter.dart';
import 'package:meter_reading_log/features/meters/domain/meter_reading.dart';
import 'package:meter_reading_log/features/meters/domain/reading_value.dart';
import 'package:meter_reading_log/features/meters/presentation/editable_reading_time_card.dart';

void main() {
  test('reading date range ends on 31 December 2100', () {
    expect(firstSelectableReadingDate, DateTime(2000));
    expect(lastSelectableReadingDate, DateTime(2100, 12, 31));
    expect(
      isFutureReadingTime(
        DateTime(2030, 1, 2),
        comparedTo: DateTime(2030, 1, 1),
      ),
      isTrue,
    );
  });

  test('future-at-storage status produces the evidence notice', () {
    final reading = _reading(
      capturedAt: DateTime.utc(2100, 1, 1),
      storedAt: DateTime.utc(2026, 9, 2),
    );

    expect(reading.wasFutureAtStorage, isTrue);
    expect(
      futureReadingEvidenceNotice(reading),
      'Beim Speichern lag der angegebene Ablesezeitpunkt in der Zukunft.',
    );
  });

  testWidgets('future reading time is visible and requires confirmation', (
    tester,
  ) async {
    bool? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Column(
              children: [
                EditableReadingTimeCard(
                  value: DateTime(2100, 1, 1, 12),
                  onPressed: () {},
                ),
                FilledButton(
                  onPressed: () async {
                    result = await confirmFutureReadingTime(
                      context,
                      DateTime(2100, 1, 1, 12),
                    );
                  },
                  child: const Text('Speichern'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('Zeitpunkt der Ablesung'), findsOneWidget);
    expect(find.textContaining('liegt in der Zukunft'), findsOneWidget);
    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();
    expect(find.text('Zukünftigen Zeitpunkt speichern?'), findsOneWidget);
    expect(result, isNull);

    await tester.tap(find.text('Trotzdem speichern'));
    await tester.pumpAndSettle();
    expect(result, isTrue);
  });
}

MeterReading _reading({
  required DateTime capturedAt,
  required DateTime storedAt,
}) {
  return MeterReading(
    id: 'reading_1',
    meterId: 'meter_1',
    meter: const MeterSnapshot(
      id: 'meter_1',
      label: 'Testzähler',
      type: MeterType.other,
      unit: 'Zyklen',
      meterNumber: '',
      location: '',
    ),
    value: ReadingValue.tryParse('12')!,
    capturedAt: capturedAt,
    timezoneOffsetMinutes: 0,
    storedAt: storedAt,
    updatedAt: storedAt,
    source: ReadingSource.camera,
    photoPath: '/tmp/photo.jpg',
    photoSha256: 'a' * 64,
    ocrRawText: '12',
    ocrCandidate: '12',
    manifestSha256: 'b' * 64,
  );
}
