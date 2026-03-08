import 'package:flutter_test/flutter_test.dart';
import 'dart:io';

void main() {
  test('convert relative imports to absolute', () async {
    final libDir = Directory('lib');
    final packagePrefix = 'package:dementia_care_app/';
    int changedCount = 0;

    await for (var entity in libDir.list(recursive: true, followLinks: false)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        final content = await entity.readAsString();

        final exp = RegExp(r"(import|export|part)\s+'([^']+)'");

        final newContent = content.replaceAllMapped(exp, (match) {
          final type = match.group(1)!;
          final path = match.group(2)!;

          if (path.startsWith('package:') ||
              path.startsWith('dart:') ||
              path.startsWith('http')) {
            return "$type '$path'";
          }

          final fileUri = Uri.file(entity.absolute.path.replaceAll(r'\', '/'));
          final resolvedUri = fileUri.resolve(path);
          final libUri =
              Uri.file(libDir.absolute.path.replaceAll(r'\', '/') + '/');

          final resolvedPathString = resolvedUri.path.toLowerCase();
          final libPathString = libUri.path.toLowerCase();

          if (resolvedPathString.startsWith(libPathString)) {
            final relPath = resolvedUri.path.substring(libUri.path.length);
            return "$type '$packagePrefix$relPath'";
          }

          return "$type '$path'";
        });

        if (newContent != content) {
          await entity.writeAsString(newContent);
          changedCount++;
        }
      }
    }

    print('Changed $changedCount files to absolute imports.');
  });
}
