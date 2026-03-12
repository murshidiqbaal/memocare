import 'dart:io';

void main() async {
  try {
    final libDir = Directory('d:/vscode/memocare/memocare/lib');
    final packagePrefix = 'package:memocare/';
    int changedCount = 0;
    StringBuffer log = StringBuffer();
    log.writeln("Starting migration...");

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
          log.writeln('Changed: ${entity.path}');
        }
      }
    }

    log.writeln('Changed $changedCount files to absolute imports.');
    await File('migration_result.txt').writeAsString(log.toString());
  } catch (e, stacktrace) {
    await File('migration_error.txt')
        .writeAsString('Error: $e\n\nStacktrace: $stacktrace');
  }
}
