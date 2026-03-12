import 'dart:io';

void main() async {
  final packageName = 'memocare';
  final libDir = Directory('lib');
  final libAbsolute = libDir.absolute.path.replaceAll('\\', '/');
  final logFile = File('migration_log.txt');
  final sink = logFile.openWrite();
  int changedCount = 0;

  sink.writeln('Starting migration...');
  sink.writeln('Lib absolute: $libAbsolute');

  List<FileSystemEntity> entities = libDir.listSync(recursive: true);
  sink.writeln('Found ${entities.length} total entities in lib.');

  for (var entity in entities) {
    if (entity is File && entity.path.endsWith('.dart')) {
      final file = entity;
      final content = await file.readAsString();
      final filePath = file.absolute.path.replaceAll('\\', '/');
      final fileDir = filePath.substring(0, filePath.lastIndexOf('/'));

      final exp = RegExp(r"(import|export|part)\s+'([^']+)'");
      bool fileChanged = false;

      final newContent = content.replaceAllMapped(exp, (match) {
        final keyword = match.group(1)!;
        final importPath = match.group(2)!;

        if (importPath.startsWith('package:') ||
            importPath.startsWith('dart:') ||
            importPath.startsWith('http')) {
          return match.group(0)!;
        }

        // Manual relative resolution
        List<String> dirParts = fileDir.split('/');
        List<String> impParts = importPath.split('/');

        List<String> resolvedParts = List.from(dirParts);
        for (final part in impParts) {
          if (part == '.') continue;
          if (part == '..') {
            if (resolvedParts.isNotEmpty) resolvedParts.removeLast();
          } else {
            resolvedParts.add(part);
          }
        }

        String resolvedPath = resolvedParts.join('/');

        // Use case-insensitive check for Windows
        if (resolvedPath.toLowerCase().startsWith(libAbsolute.toLowerCase())) {
          String relativeToLib = resolvedPath.substring(libAbsolute.length);
          if (relativeToLib.startsWith('/'))
            relativeToLib = relativeToLib.substring(1);
          fileChanged = true;
          return "$keyword 'package:$packageName/$relativeToLib'";
        }

        return match.group(0)!;
      });

      if (fileChanged) {
        await file.writeAsString(newContent);
        changedCount++;
        sink.writeln('Updated: $filePath');
      }
    }
  }

  sink.writeln('FINISHED: Converted $changedCount files.');
  await sink.close();
}
