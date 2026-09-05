import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meter_reading_log/app/app.dart';
import 'package:meter_reading_log/app/app_providers.dart';
import 'package:meter_reading_log/core/files/meter_photo_repository.dart';
import 'package:meter_reading_log/core/reminders/local_notification_reminder_repository.dart';
import 'package:meter_reading_log/features/meters/domain/meter.dart';
import 'package:meter_reading_log/features/meters/domain/meter_reading.dart';
import 'package:meter_reading_log/features/meters/domain/reading_value.dart';

import 'support/fakes.dart';

void main() {
  testWidgets('empty app opens meter creation flow', (tester) async {
    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();

    expect(find.text('Ersten Zähler anlegen'), findsOneWidget);
    await tester.tap(find.text('Zähler anlegen'));
    await tester.pumpAndSettle();

    expect(find.text('Zählerart'), findsOneWidget);
    expect(find.text('Bezeichnung *'), findsOneWidget);
    expect(find.text('Einheit *'), findsOneWidget);
    expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
    expect(find.text('Ableseerinnerung'), findsOneWidget);
    expect(
      tester.widget<ListView>(find.byType(ListView)).keyboardDismissBehavior,
      ScrollViewKeyboardDismissBehavior.onDrag,
    );
  });

  testWidgets('reminder time uses a clearly clickable full-width button', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Zähler anlegen'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ableseerinnerung'));
    await tester.pumpAndSettle();
    final timeButton = find.widgetWithText(OutlinedButton, 'Uhrzeit ändern');
    expect(timeButton, findsOneWidget);
    await tester.ensureVisible(timeButton);
    await tester.pumpAndSettle();
    expect(
      tester.getSize(timeButton).width,
      greaterThan(tester.getSize(find.text('Uhrzeit ändern')).width * 2),
    );

    await tester.tap(timeButton);
    await tester.pumpAndSettle();
    expect(find.byType(TimePickerDialog), findsOneWidget);
  });

  testWidgets('reminders support dev, daily and weekly intervals', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final meters = MemoryMeterRepository();
    await tester.pumpWidget(_testApp(meters: meters));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Zähler anlegen'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Bezeichnung *'),
      'Wasser wöchentlich',
    );

    await tester.tap(find.text('Ableseerinnerung'));
    await tester.pumpAndSettle();
    final intervalField = find.byType(
      DropdownButtonFormField<ReminderInterval>,
    );
    await tester.ensureVisible(intervalField);
    await tester.tap(intervalField);
    await tester.pumpAndSettle();
    expect(find.text('Minütlich (Dev)'), findsOneWidget);
    expect(find.text('Täglich'), findsOneWidget);
    expect(find.text('Wöchentlich'), findsOneWidget);

    await tester.tap(find.text('Minütlich (Dev)'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Die nächste Erinnerung'), findsOneWidget);
    expect(find.text('Uhrzeit ändern'), findsNothing);

    await tester.tap(intervalField);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Täglich'));
    await tester.pumpAndSettle();
    expect(find.text('Wochentag'), findsNothing);
    expect(find.text('Tag'), findsNothing);

    await tester.tap(intervalField);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Wöchentlich').last);
    await tester.pumpAndSettle();
    expect(find.text('Wochentag'), findsOneWidget);

    final weekdayField = find.byType(DropdownButtonFormField<int>);
    await tester.tap(weekdayField);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Montag').last);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Zähler speichern'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Zähler speichern'));
    for (var attempt = 0; attempt < 30 && meters.items.isEmpty; attempt++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pump();

    final reminder = meters.items.values.single.reminder!;
    expect(reminder.interval, ReminderInterval.weekly);
    expect(reminder.day, DateTime.monday);
  });

  testWidgets('normal reminder test shows progress and uses meter details', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final meter =
        _meter(
          id: 'reminder_test_meter',
          label: 'Strom Keller',
          type: MeterType.electricity,
          location: 'Keller',
          updatedAt: DateTime.utc(2026, 9, 5),
        ).copyWith(
          reminder: const ReadingReminderSchedule(
            interval: ReminderInterval.daily,
            day: 1,
            hour: 9,
            minute: 0,
          ),
        );
    final meters = MemoryMeterRepository()..items[meter.id] = meter;
    final reading = _reading(
      meter: meter,
      updatedAt: DateTime.utc(2026, 9, 5, 10),
    );
    final readings = MemoryReadingRepository()..items[reading.id] = reading;
    final reminders = _PendingReminderTestRepository();
    await tester.pumpWidget(
      _testApp(meters: meters, readings: readings, reminders: reminders),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Strom Keller'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(OutlinedButton, 'Zähler & Erinnerung bearbeiten'),
    );
    await tester.pumpAndSettle();

    final button = find.widgetWithText(
      OutlinedButton,
      'Erinnerung jetzt testen',
    );
    await tester.scrollUntilVisible(
      button,
      250,
      scrollable: find.byType(Scrollable).last,
    );
    expect(button, findsOneWidget);
    expect(find.text('Ton jetzt testen'), findsNothing);
    await tester.tap(button);
    await tester.pump();

    expect(reminders.reminderTests, hasLength(1));
    final request = reminders.reminderTests.single;
    expect(request.deliveryMode, ReminderDeliveryMode.normal);
    expect(request.meterId, meter.id);
    expect(request.label, meter.label);
    expect(request.meterType, MeterType.electricity);
    expect(request.latestValue, reading.value.displayText);
    expect(request.latestUnit, reading.meter.unit);
    expect(
      find.descendant(
        of: button,
        matching: find.byType(CircularProgressIndicator),
      ),
      findsOneWidget,
    );
    expect(tester.widget<OutlinedButton>(button).onPressed, isNull);

    reminders.completeTest(true);
    await tester.pumpAndSettle();
    expect(find.text('Test-Erinnerung wurde ausgelöst.'), findsOneWidget);
  });

  testWidgets(
    'punctual reminder uses the same test button and reports denial',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final reminders = NoopMeterReminderRepository(
        reminderTestResult: false,
        permission: ReminderPermissionStatus.denied,
      );
      await tester.pumpWidget(_testApp(reminders: reminders));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Zähler anlegen'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Bezeichnung *'),
        'Strom pünktlich',
      );

      await tester.tap(find.text('Ableseerinnerung'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Pünktlich mit Ton'));
      await tester.tap(find.text('Pünktlich mit Ton'));
      await tester.pumpAndSettle();

      final alarmSettings = find.widgetWithText(
        OutlinedButton,
        '„Alarme & Erinnerungen“ öffnen',
      );
      expect(alarmSettings, findsOneWidget);
      await tester.tap(alarmSettings);
      await tester.pump();
      expect(reminders.exactAlarmSettingsOpenCount, 1);
      expect(find.text('Ton jetzt testen'), findsNothing);
      expect(find.text('Erinnerung jetzt testen'), findsOneWidget);
      await tester.tap(find.text('Erinnerung jetzt testen'));
      await tester.pumpAndSettle();
      expect(reminders.reminderTests, hasLength(1));
      expect(
        reminders.reminderTests.single.deliveryMode,
        ReminderDeliveryMode.punctualWithSound,
      );
      expect(
        find.text('Benachrichtigungen sind nicht erlaubt.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('meter form offers expanded types and matching units', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Zähler anlegen'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<MeterType>));
    await tester.pumpAndSettle();

    expect(find.text('Strom (Einspeisung / PV)'), findsOneWidget);
    expect(find.text('Warmwasser'), findsOneWidget);
    expect(find.text('Wärme / Fernwärme'), findsOneWidget);
    expect(find.text('Heizkostenverteiler'), findsOneWidget);
    expect(find.text('Heizöl / Tank'), findsOneWidget);
    expect(find.text('Sonstiger Zähler'), findsOneWidget);

    await tester.tap(find.text('Warmwasser'));
    await tester.pumpAndSettle();
    expect(find.text('m³'), findsOneWidget);

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    expect(find.text('Liter'), findsOneWidget);
  });

  testWidgets('meter form offers more units and persists a custom unit', (
    tester,
  ) async {
    final meters = MemoryMeterRepository();
    await tester.pumpWidget(_testApp(meters: meters));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Zähler anlegen'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    expect(find.text('GWh'), findsOneWidget);
    expect(find.text('kvarh'), findsOneWidget);
    expect(find.text('kVAh'), findsOneWidget);
    await tester.tap(find.text('Weitere Einheit …'));
    await tester.pumpAndSettle();

    expect(find.text('Weitere Einheit auswählen'), findsOneWidget);
    expect(find.text('Einheiten durchsuchen'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextField, 'Einheiten durchsuchen'),
      'Betriebsstunden',
    );
    await tester.pumpAndSettle();
    expect(find.text('h'), findsOneWidget);
    expect(find.text('GWh'), findsNothing);
    await tester.ensureVisible(find.text('Eigene Einheit eingeben'));
    await tester.tap(find.text('Eigene Einheit eingeben'));
    await tester.pumpAndSettle();
    final submitButton = find.widgetWithText(FilledButton, 'Übernehmen');
    final cancelButton = find.widgetWithText(OutlinedButton, 'Abbrechen');
    expect(submitButton, findsOneWidget);
    expect(cancelButton, findsOneWidget);
    expect(
      tester.getSize(submitButton).width,
      tester.getSize(cancelButton).width,
    );
    expect(
      tester.getTopLeft(submitButton).dy,
      lessThan(tester.getTopLeft(cancelButton).dy),
    );
    await tester.tap(find.text('Übernehmen'));
    await tester.pumpAndSettle();
    expect(find.text('Bitte eine Einheit eingeben.'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Einheit *'),
      'Zyklen',
    );
    await tester.tap(find.text('Übernehmen'));
    await tester.pumpAndSettle();

    expect(find.text('Zyklen'), findsOneWidget);
    expect(find.text('Eigene Einheit dieses Zählers'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Bezeichnung *'),
      'Maschinenzähler',
    );
    await tester.ensureVisible(find.text('Zähler speichern'));
    await tester.tap(find.text('Zähler speichern'));
    const confirmation =
        'Zähler gespeichert. Das Ablesen des Zählerstands folgt im nächsten Schritt.';
    for (var attempt = 0; attempt < 30; attempt++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.text(confirmation).evaluate().isNotEmpty) break;
    }

    expect(meters.items.values.single.unit, 'Zyklen');
    expect(find.text(confirmation), findsWidgets);
  });

  testWidgets('new meter confirms that reading follows next', (tester) async {
    final meters = MemoryMeterRepository();
    await tester.pumpWidget(_testApp(meters: meters));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Zähler anlegen'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Bezeichnung *'),
      'Strom Hauptzähler',
    );
    await tester.ensureVisible(find.text('Zähler speichern'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Zähler speichern'));
    const confirmation =
        'Zähler gespeichert. Das Ablesen des Zählerstands folgt im nächsten Schritt.';
    for (var attempt = 0; attempt < 30; attempt++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.text(confirmation).evaluate().isNotEmpty) break;
    }

    expect(meters.items.values.single.label, 'Strom Hauptzähler');
    expect(find.text(confirmation), findsWidgets);
    expect(find.text('Ablesen / Fotografieren'), findsOneWidget);

    expect(await tester.binding.handlePopRoute(), isTrue);
    await tester.pumpAndSettle();

    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Ablesen / Fotografieren'), findsNothing);
  });

  testWidgets('meter edit and delete actions are visible below its summary', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final meters = MemoryMeterRepository();
    final meter =
        _meter(
          id: 'weekly_meter',
          label: 'Wasser Garten',
          type: MeterType.water,
          location: 'Garten',
          updatedAt: DateTime.utc(2026, 9, 4),
        ).copyWith(
          reminder: const ReadingReminderSchedule(
            interval: ReminderInterval.weekly,
            day: DateTime.friday,
            hour: 9,
            minute: 0,
          ),
        );
    meters.items[meter.id] = meter;

    await tester.pumpWidget(_testApp(meters: meters));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Wasser Garten'));
    await tester.pumpAndSettle();

    final edit = find.widgetWithText(
      OutlinedButton,
      'Zähler & Erinnerung bearbeiten',
    );
    final delete = find.widgetWithText(OutlinedButton, 'Zähler löschen');
    expect(edit, findsOneWidget);
    expect(delete, findsOneWidget);
    expect(find.byType(PopupMenuButton<String>), findsNothing);
    expect(
      find.text('Erinnerung: wöchentlich am Freitag um 09:00 Uhr'),
      findsOneWidget,
    );
    expect(
      tester.getBottomLeft(find.byType(Card).first).dy,
      lessThan(tester.getTopLeft(edit).dy),
    );
    expect(
      tester.getTopLeft(delete).dy,
      lessThan(tester.getTopLeft(find.text('Zählerverlauf')).dy),
    );

    await tester.tap(find.byKey(const ValueKey('meter-summary-weekly_meter')));
    await tester.pumpAndSettle();
    expect(find.text('Zähler bearbeiten'), findsOneWidget);
  });

  testWidgets('meter edit keeps save visible and protects unsaved changes', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final meters = MemoryMeterRepository();
    final meter = _meter(
      id: 'protected_meter',
      label: 'Strom Keller',
      type: MeterType.electricity,
      location: 'Keller',
      updatedAt: DateTime.utc(2026, 9, 4),
    );
    meters.items[meter.id] = meter;

    await tester.pumpWidget(_testApp(meters: meters));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Strom Keller'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Zähler & Erinnerung bearbeiten'));
    await tester.pumpAndSettle();

    final savedButton = find.widgetWithText(FilledButton, 'Alles gespeichert');
    expect(savedButton, findsOneWidget);
    expect(savedButton.hitTestable(), findsOneWidget);
    expect(tester.widget<FilledButton>(savedButton).onPressed, isNull);

    final labelField = find.widgetWithText(TextFormField, 'Bezeichnung *');
    await tester.enterText(labelField, 'Strom Hauptzähler');
    await tester.pump();
    final saveButton = find.widgetWithText(
      FilledButton,
      'Änderungen speichern',
    );
    expect(saveButton, findsOneWidget);
    expect(tester.widget<FilledButton>(saveButton).onPressed, isNotNull);

    expect(await tester.binding.handlePopRoute(), isTrue);
    await tester.pumpAndSettle();
    expect(find.text('Änderungen verwerfen?'), findsOneWidget);
    expect(
      find.text(
        'Deine Änderungen an diesem Zähler wurden noch nicht gespeichert.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Weiter bearbeiten'));
    await tester.pumpAndSettle();
    expect(find.text('Zähler bearbeiten'), findsOneWidget);
    expect(
      tester.widget<TextFormField>(labelField).controller?.text,
      'Strom Hauptzähler',
    );

    expect(await tester.binding.handlePopRoute(), isTrue);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Änderungen verwerfen'));
    await tester.pumpAndSettle();

    expect(find.text('Zähler bearbeiten'), findsNothing);
    expect(meters.items[meter.id]!.label, 'Strom Keller');
  });

  testWidgets('selecting minutely enables saving for a changed reminder', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final meter =
        _meter(
          id: 'daily_meter',
          label: 'Strom täglich',
          type: MeterType.electricity,
          location: 'Keller',
          updatedAt: DateTime.utc(2026, 9, 4),
        ).copyWith(
          reminder: const ReadingReminderSchedule(
            interval: ReminderInterval.daily,
            day: 1,
            hour: 6,
            minute: 0,
          ),
        );
    final meters = MemoryMeterRepository()..items[meter.id] = meter;

    await tester.pumpWidget(_testApp(meters: meters));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Strom täglich'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Zähler & Erinnerung bearbeiten'));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Alles gespeichert'),
          )
          .onPressed,
      isNull,
    );

    final intervalField = find.byType(
      DropdownButtonFormField<ReminderInterval>,
    );
    await tester.tap(intervalField);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Minütlich (Dev)').last);
    await tester.pumpAndSettle();

    final saveButton = find.widgetWithText(
      FilledButton,
      'Änderungen speichern',
    );
    expect(saveButton, findsOneWidget);
    expect(tester.widget<FilledButton>(saveButton).onPressed, isNotNull);
  });

  testWidgets('system back returns from settings', (tester) async {
    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Einstellungen'));
    await tester.pumpAndSettle();
    expect(find.text('Einstellungen'), findsOneWidget);
    expect(find.text('PDF auf Änderungen prüfen'), findsNothing);
    expect(find.text('Nachweise'), findsNothing);

    expect(await tester.binding.handlePopRoute(), isTrue);
    await tester.pumpAndSettle();
    expect(find.text('Dashboard'), findsOneWidget);
  });

  testWidgets('notification meter has back button and edge back to dashboard', (
    tester,
  ) async {
    final meter = _meter(
      id: 'notification_meter',
      label: 'Strom aus Erinnerung',
      type: MeterType.electricity,
      location: 'Keller',
      updatedAt: DateTime.utc(2026, 9, 5),
    );
    final meters = MemoryMeterRepository()..items[meter.id] = meter;
    final reminders = NoopMeterReminderRepository(initialMeterId: meter.id);

    await tester.pumpWidget(_testApp(meters: meters, reminders: reminders));
    await tester.pumpAndSettle();

    expect(find.text('Strom aus Erinnerung'), findsWidgets);
    expect(find.byType(BackButton), findsOneWidget);
    expect(await tester.binding.handlePopRoute(), isTrue);
    await tester.pumpAndSettle();
    expect(find.text('Dashboard'), findsOneWidget);

    await tester.tap(find.text('Strom aus Erinnerung'));
    await tester.pumpAndSettle();
    expect(find.byType(BackButton), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Dashboard'), findsOneWidget);
  });

  testWidgets('dashboard searches, sorts and shows last edited dates', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final meters = MemoryMeterRepository();
    final readings = MemoryReadingRepository();
    final alpha = _meter(
      id: 'alpha',
      label: 'Alpha Wasser',
      type: MeterType.water,
      location: 'Bad',
      updatedAt: DateTime.utc(2026, 9, 1, 8),
    );
    final beta = _meter(
      id: 'beta',
      label: 'Beta Strom',
      type: MeterType.electricity,
      location: 'Keller',
      updatedAt: DateTime.utc(2026, 8, 30, 8),
    );
    meters.items.addAll({alpha.id: alpha, beta.id: beta});
    readings.items['reading_beta'] = _reading(
      meter: beta,
      updatedAt: DateTime.utc(2026, 9, 2, 12),
    );

    await tester.pumpWidget(_testApp(meters: meters, readings: readings));
    await tester.pumpAndSettle();

    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Zähler suchen'), findsOneWidget);
    expect(find.text('Zuletzt bearbeitet'), findsOneWidget);
    expect(find.textContaining('Zuletzt bearbeitet:'), findsNWidgets(2));
    expect(
      tester.getTopLeft(find.text('Beta Strom')).dy,
      lessThan(tester.getTopLeft(find.text('Alpha Wasser')).dy),
    );

    await tester.enterText(
      find.widgetWithText(TextField, 'Zähler suchen'),
      'bad',
    );
    await tester.pumpAndSettle();
    expect(find.text('1 Treffer'), findsOneWidget);
    expect(find.text('Alpha Wasser'), findsOneWidget);
    expect(find.text('Beta Strom'), findsNothing);

    await tester.tap(find.byTooltip('Suche löschen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Zuletzt bearbeitet'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Name A–Z'));
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.text('Alpha Wasser')).dy,
      lessThan(tester.getTopLeft(find.text('Beta Strom')).dy),
    );
  });

  testWidgets(
    'dashboard card acknowledges active reminder and keeps trigger time',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final meter =
          _meter(
            id: 'active_reminder',
            label: 'Gas Keller',
            type: MeterType.gas,
            location: 'Keller',
            updatedAt: DateTime(2026, 9, 4),
          ).copyWith(
            reminder: const ReadingReminderSchedule(
              interval: ReminderInterval.daily,
              day: 1,
              hour: 6,
              minute: 0,
            ),
          );
      final meters = MemoryMeterRepository()..items[meter.id] = meter;
      final reminders = NoopMeterReminderRepository(
        statuses: {
          meter.id: ReminderStatus(
            meterId: meter.id,
            isNotificationActive: true,
            lastTriggeredAt: DateTime(2026, 9, 5, 6, 1),
          ),
        },
      );

      await tester.pumpWidget(_testApp(meters: meters, reminders: reminders));
      await tester.pumpAndSettle();

      expect(find.text('Erinnern: täglich um 06:00 Uhr'), findsOneWidget);
      final nextReminder = find.byKey(
        const ValueKey('next-reminder-active_reminder'),
      );
      expect(nextReminder, findsOneWidget);
      expect(
        find.descendant(
          of: nextReminder,
          matching: find.text('Nächste Erinnerung'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: nextReminder,
          matching: find.textContaining('06:00 Uhr'),
        ),
        findsOneWidget,
      );
      expect(
        find.text('Letzte Erinnerung: 05.09.2026, 06:01 Uhr'),
        findsOneWidget,
      );
      final badge = tester.widget<Badge>(find.byType(Badge));
      expect(badge.isLabelVisible, isTrue);
      expect(find.text('1'), findsOneWidget);

      await tester.tap(find.text('Gas Keller'));
      await tester.pumpAndSettle();
      expect(reminders.acknowledgedMeterIds, [meter.id]);

      expect(await tester.binding.handlePopRoute(), isTrue);
      await tester.pumpAndSettle();
      expect(tester.widget<Badge>(find.byType(Badge)).isLabelVisible, isFalse);
      expect(find.text('1'), findsNothing);
      expect(
        find.text('Letzte Erinnerung: 05.09.2026, 06:01 Uhr'),
        findsOneWidget,
      );
      expect(nextReminder, findsOneWidget);
    },
  );
}

Widget _testApp({
  MemoryMeterRepository? meters,
  MemoryReadingRepository? readings,
  NoopMeterReminderRepository? reminders,
}) {
  return ProviderScope(
    overrides: [
      meterRepositoryProvider.overrideWithValue(
        meters ?? MemoryMeterRepository(),
      ),
      meterReadingRepositoryProvider.overrideWithValue(
        readings ?? MemoryReadingRepository(),
      ),
      evidenceExportRepositoryProvider.overrideWithValue(
        MemoryEvidenceExportRepository(),
      ),
      meterPhotoCaptureRepositoryProvider.overrideWithValue(
        const UnsupportedMeterPhotoCaptureRepository(),
      ),
      meterReminderRepositoryProvider.overrideWithValue(
        reminders ?? NoopMeterReminderRepository(),
      ),
    ],
    child: const MeterReadingLogApp(),
  );
}

Meter _meter({
  required String id,
  required String label,
  required MeterType type,
  required String location,
  required DateTime updatedAt,
}) {
  return Meter(
    id: id,
    label: label,
    type: type,
    unit: type == MeterType.water ? 'm³' : 'kWh',
    meterNumber: '${id}_number',
    location: location,
    createdAt: DateTime.utc(2026, 8, 1),
    updatedAt: updatedAt,
  );
}

MeterReading _reading({required Meter meter, required DateTime updatedAt}) {
  return MeterReading(
    id: 'reading_${meter.id}',
    meterId: meter.id,
    meter: MeterSnapshot.fromMeter(meter),
    value: ReadingValue.tryParse('123,4')!,
    capturedAt: DateTime.utc(2026, 9, 2, 10),
    timezoneOffsetMinutes: 120,
    storedAt: updatedAt,
    updatedAt: updatedAt,
    source: ReadingSource.camera,
    photoPath: '/tmp/photo.jpg',
    photoSha256: 'a' * 64,
    ocrRawText: '123,4',
    ocrCandidate: '123,4',
    manifestSha256: 'b' * 64,
  );
}

class _PendingReminderTestRepository extends NoopMeterReminderRepository {
  final Completer<bool> _test = Completer<bool>();

  @override
  Future<bool> showReminderTest(MeterReminderTestRequest request) {
    reminderTests.add(request);
    return _test.future;
  }

  void completeTest(bool result) => _test.complete(result);
}
