import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/backup/presentation/settings_screen.dart';
import '../features/evidence/application/evidence_report_service.dart';
import '../features/evidence/presentation/evidence_preview_screen.dart';
import '../features/meters/presentation/capture_reading_screen.dart';
import '../features/meters/presentation/edit_reading_screen.dart';
import '../features/meters/presentation/home_screen.dart';
import '../features/meters/presentation/meter_detail_screen.dart';
import '../features/meters/presentation/meter_form_screen.dart';
import '../features/meters/presentation/reading_detail_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    routes: [
      GoRoute(path: '/', name: 'home', builder: (_, _) => const HomeScreen()),
      GoRoute(
        path: '/meter/new',
        name: 'meterNew',
        builder: (_, _) => const MeterFormScreen(),
      ),
      GoRoute(
        path: '/meter/:id',
        name: 'meterDetail',
        builder: (_, state) =>
            MeterDetailScreen(meterId: state.pathParameters['id'] ?? ''),
      ),
      GoRoute(
        path: '/meter/:id/edit',
        name: 'meterEdit',
        builder: (_, state) =>
            MeterFormScreen(meterId: state.pathParameters['id'] ?? ''),
      ),
      GoRoute(
        path: '/meter/:id/capture',
        name: 'captureReading',
        builder: (_, state) =>
            CaptureReadingScreen(meterId: state.pathParameters['id'] ?? ''),
      ),
      GoRoute(
        path: '/reading/:id',
        name: 'readingDetail',
        builder: (_, state) =>
            ReadingDetailScreen(readingId: state.pathParameters['id'] ?? ''),
      ),
      GoRoute(
        path: '/reading/:id/edit',
        name: 'readingEdit',
        builder: (_, state) =>
            EditReadingScreen(readingId: state.pathParameters['id'] ?? ''),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (_, _) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/evidence-preview',
        name: 'evidencePreview',
        builder: (_, state) {
          final report = state.extra;
          if (report is! GeneratedEvidenceReport) {
            return const HomeScreen();
          }
          return EvidencePreviewScreen(report: report);
        },
      ),
    ],
  );
});
