import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meter_reading_log/core/integrity/integrity_copy.dart';
import 'package:meter_reading_log/features/backup/presentation/settings_screen.dart';
import 'package:meter_reading_log/features/evidence/presentation/evidence_verify_screen.dart';

void main() {
  testWidgets('settings describes PDF verification without technical jargon', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: SettingsScreen())),
    );

    expect(find.text(pdfVerificationTitle), findsOneWidget);
    expect(
      find.textContaining('ob eine von dieser App erstellte PDF verändert'),
      findsOneWidget,
    );
  });

  testWidgets('verification screen explains comparison and its limitation', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: EvidenceVerifyScreen())),
    );

    expect(find.text(pdfVerificationTitle), findsNWidgets(2));
    expect(find.text(pdfVerificationText), findsOneWidget);
    expect(find.text(privateDocumentationText), findsOneWidget);
  });
}
