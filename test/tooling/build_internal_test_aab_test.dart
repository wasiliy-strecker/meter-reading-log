import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group(
    'internal test AAB helper',
    () {
      late Directory project;
      late File helper;
      late File fakeFlutter;
      late File metadata;
      late File sourceBundle;
      late File output;

      Future<ProcessResult> runHelper({
        List<String> arguments = const [],
        int buildExitCode = 0,
      }) => Process.run(
        'bash',
        [helper.path, ...arguments],
        workingDirectory: Directory.systemTemp.path,
        environment: {
          'FLUTTER_BIN': fakeFlutter.path,
          'FAKE_FLUTTER_EXIT_CODE': '$buildExitCode',
        },
      );

      Future<void> writeMetadata({
        String applicationId = 'com.appfactory.meter_reading_log',
        String variantName = 'storeRelease',
        String versionName = '1.2.3',
        int versionCode = 42,
      }) => metadata.writeAsString(
        jsonEncode({
          'applicationId': applicationId,
          'variantName': variantName,
          'elements': [
            {'versionName': versionName, 'versionCode': versionCode},
          ],
        }),
      );

      setUp(() async {
        project = await Directory.systemTemp.createTemp('zsl release helper ');
        helper = File('${project.path}/scripts/build_internal_test_aab.sh');
        await helper.parent.create(recursive: true);
        await File('scripts/build_internal_test_aab.sh').copy(helper.path);
        await File(
          '${project.path}/pubspec.yaml',
        ).writeAsString('name: synthetic_fixture\nversion: 1.2.3+42\n');
        fakeFlutter = File('${project.path}/fake flutter');
        await fakeFlutter.writeAsString(r'''#!/usr/bin/env bash
printf '%s\n' "$@" > flutter-args.txt
exit "${FAKE_FLUTTER_EXIT_CODE:-0}"
''');
        final chmod = await Process.run('chmod', ['+x', fakeFlutter.path]);
        expect(chmod.exitCode, 0);
        metadata = File(
          '${project.path}/build/app/intermediates/merged_manifests/'
          'storeRelease/processStoreReleaseManifest/output-metadata.json',
        );
        await metadata.parent.create(recursive: true);
        await writeMetadata();
        sourceBundle = File(
          '${project.path}/build/app/outputs/bundle/storeRelease/'
          'app-store-release.aab',
        );
        await sourceBundle.parent.create(recursive: true);
        await sourceBundle.writeAsBytes([0, 1, 2, 127, 255]);
        output = File(
          '${project.path}/build/releases/internal-test/'
          'zaehlerstandlog-1.2.3-build-42-internal-test.aab',
        );
      });

      tearDown(() async {
        await project.delete(recursive: true);
      });

      test(
        'builds only store/release and copies a versioned artifact',
        () async {
          final result = await runHelper();

          expect(
            result.exitCode,
            0,
            reason: '${result.stdout}\n${result.stderr}',
          );
          expect(await output.readAsBytes(), await sourceBundle.readAsBytes());
          expect(result.stdout, contains(output.path));
          expect(result.stdout, contains('Version: 1.2.3 (code 42)'));
          expect(await File('${project.path}/flutter-args.txt').readAsLines(), [
            'build',
            'appbundle',
            '--release',
            '--flavor',
            'store',
          ]);
          expect(
            await File('${project.path}/pubspec.yaml').readAsString(),
            'name: synthetic_fixture\nversion: 1.2.3+42\n',
          );
        },
      );

      test('preserves an existing named release without rebuilding', () async {
        await output.parent.create(recursive: true);
        await output.writeAsString('previously delivered artifact');

        final result = await runHelper();

        expect(result.exitCode, isNot(0));
        expect(result.stderr, contains('Release artifact already exists'));
        expect(await output.readAsString(), 'previously delivered artifact');
        expect(File('${project.path}/flutter-args.txt').existsSync(), isFalse);
      });

      test(
        'also preserves a same-version delivery in the old folder',
        () async {
          final legacy = File(
            '${sourceBundle.parent.path}/'
            'zaehlerstandlog-1.2.3-build-42-internal-test.aab',
          );
          await legacy.writeAsString('previously delivered artifact');

          final result = await runHelper();

          expect(result.exitCode, isNot(0));
          expect(result.stderr, contains(legacy.path));
          expect(await legacy.readAsString(), 'previously delivered artifact');
          expect(output.existsSync(), isFalse);
          expect(
            File('${project.path}/flutter-args.txt').existsSync(),
            isFalse,
          );
        },
      );

      test(
        'ignores older named bundles when selecting the build result',
        () async {
          final older = File(
            '${sourceBundle.parent.path}/'
            'zaehlerstandlog-1.2.3-build-41-internal-test.aab',
          );
          await older.writeAsString('older release');

          final result = await runHelper();

          expect(
            result.exitCode,
            0,
            reason: '${result.stdout}\n${result.stderr}',
          );
          expect(await output.readAsBytes(), await sourceBundle.readAsBytes());
          expect(await older.readAsString(), 'older release');
          expect(output.path, isNot(startsWith(sourceBundle.parent.path)));
        },
      );

      test('rejects overrides of flavor, build mode, or version', () async {
        final result = await runHelper(
          arguments: ['--flavor', 'dev', '--debug', '--build-number', '99'],
        );

        expect(result.exitCode, isNot(0));
        expect(result.stderr, contains('No arguments supported'));
        expect(File('${project.path}/flutter-args.txt').existsSync(), isFalse);
        expect(output.existsSync(), isFalse);
      });

      test('requires an explicit build number before building', () async {
        await File(
          '${project.path}/pubspec.yaml',
        ).writeAsString('version: 1.2.3');

        final result = await runHelper();

        expect(result.exitCode, isNot(0));
        expect(result.stderr, contains('explicit positive build number'));
        expect(File('${project.path}/flutter-args.txt').existsSync(), isFalse);
      });

      test('does not deliver a stale artifact after a failed build', () async {
        final result = await runHelper(buildExitCode: 23);

        expect(result.exitCode, 23);
        expect(output.existsSync(), isFalse);
        expect(sourceBundle.existsSync(), isTrue);
      });

      test('rejects a different package', () async {
        await writeMetadata(
          applicationId: 'com.appfactory.meter_reading_log.dev',
        );

        final result = await runHelper();

        expect(result.exitCode, isNot(0));
        expect(result.stderr, contains('does not match store/release'));
        expect(output.existsSync(), isFalse);
      });

      test('rejects a different build variant', () async {
        await writeMetadata(variantName: 'storeDebug');

        final result = await runHelper();

        expect(result.exitCode, isNot(0));
        expect(output.existsSync(), isFalse);
      });

      test('rejects a different version name', () async {
        await writeMetadata(versionName: '1.2.2');

        final result = await runHelper();

        expect(result.exitCode, isNot(0));
        expect(output.existsSync(), isFalse);
      });

      test('rejects a different version code', () async {
        await writeMetadata(versionCode: 41);

        final result = await runHelper();

        expect(result.exitCode, isNot(0));
        expect(output.existsSync(), isFalse);
      });

      test('rejects missing metadata', () async {
        await metadata.delete();

        final result = await runHelper();

        expect(result.exitCode, isNot(0));
        expect(result.stderr, contains('metadata is missing'));
        expect(output.existsSync(), isFalse);
      });

      test('rejects invalid metadata', () async {
        await metadata.writeAsString('invalid json');

        final result = await runHelper();

        expect(result.exitCode, isNot(0));
        expect(output.existsSync(), isFalse);
      });

      for (final missing in [true, false]) {
        test('rejects a ${missing ? 'missing' : 'empty'} bundle', () async {
          if (missing) {
            await sourceBundle.delete();
          } else {
            await sourceBundle.writeAsString('');
          }

          final result = await runHelper();

          expect(result.exitCode, isNot(0));
          expect(result.stderr, contains('AAB is missing or empty'));
          expect(output.existsSync(), isFalse);
        });
      }
    },
    skip: Platform.isWindows
        ? 'The release helper requires Bash and jq.'
        : false,
  );
}
