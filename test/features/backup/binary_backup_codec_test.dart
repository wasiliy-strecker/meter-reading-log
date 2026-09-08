import 'dart:io';

import 'package:archive/archive.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meter_reading_log/features/backup/application/binary_backup_codec.dart';

void main() {
  test('binary backup authenticates every stored asset', () async {
    final temp = await Directory.systemTemp.createTemp('binary_backup_codec_');
    addTearDown(() => temp.delete(recursive: true));
    final source = File('${temp.path}/photo.jpg');
    final sourceBytes = List<int>.generate(256 * 1024, (index) => index % 251);
    await source.writeAsBytes(sourceBytes);
    final sha256 = _hex((await Sha256().hash(sourceBytes)).bytes);
    final backup = File('${temp.path}/backup.zslbackup');

    await createBinaryBackupArchive({
      'outputPath': backup.path,
      'password': '123456',
      'iterations': 1000,
      'payload': {
        'manifest': {
          'format': binaryBackupFormat,
          'schemaVersion': binaryBackupVersion,
          'createdAt': DateTime.utc(2026, 9, 8).toIso8601String(),
          'meterCount': 0,
          'readingCount': 0,
          'exportCount': 0,
        },
        'meters': <Object>[],
        'readings': <Object>[],
        'revisions': <String, Object>{},
        'exports': <Object>[],
        'files': [
          {
            'kind': 'photo',
            'ownerId': 'reading_1',
            'fileName': 'photo.jpg',
            'sha256': sha256,
            'assetSha256': sha256,
          },
        ],
      },
      'assets': [
        {'sha256': sha256, 'path': source.path},
      ],
    }, (_) {});

    final validReader = await BinaryBackupReader.open(backup.path, '123456');
    expect(await validReader.readAsset(sha256), sourceBytes);
    validReader.close();

    await expectLater(
      BinaryBackupReader.open(backup.path, '654321'),
      throwsA(
        isA<BinaryBackupCodecException>().having(
          (error) => error.code,
          'code',
          'invalidPassword',
        ),
      ),
    );

    final archiveInput = InputFileStream(backup.path);
    final archive = ZipDecoder().decodeStream(archiveInput);
    final encrypted = archive.findFile('assets/$sha256.bin')!.readBytes()!;
    archive.clearSync();
    archiveInput.closeSync();
    final backupBytes = await backup.readAsBytes();
    final encryptedOffset = _indexOf(backupBytes, encrypted.sublist(0, 32));
    expect(encryptedOffset, greaterThanOrEqualTo(0));
    backupBytes[encryptedOffset + 10] ^= 0xff;
    final tampered = File('${temp.path}/tampered.zslbackup');
    await tampered.writeAsBytes(backupBytes);

    final tamperedReader = await BinaryBackupReader.open(
      tampered.path,
      '123456',
    );
    await expectLater(
      tamperedReader.readAsset(sha256),
      throwsA(
        isA<BinaryBackupCodecException>().having(
          (error) => error.code,
          'code',
          'integrityMismatch',
        ),
      ),
    );
    tamperedReader.close();
  });
}

int _indexOf(List<int> haystack, List<int> needle) {
  for (var start = 0; start <= haystack.length - needle.length; start += 1) {
    var matches = true;
    for (var offset = 0; offset < needle.length; offset += 1) {
      if (haystack[start + offset] != needle[offset]) {
        matches = false;
        break;
      }
    }
    if (matches) return start;
  }
  return -1;
}

String _hex(List<int> bytes) {
  final buffer = StringBuffer();
  for (final byte in bytes) {
    buffer.write(byte.toRadixString(16).padLeft(2, '0'));
  }
  return buffer.toString();
}
