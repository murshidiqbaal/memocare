import 'dart:io';

void fixFile(String path) {
  var file = File(path);
  var content = file.readAsStringSync();
  var original = content;

  // Replace `.remindAt` with `.reminderTime`
  content = content.replaceAll(RegExp(r'\bremindAt\b(?!:)'), 'reminderTime');
  // Replace `remindAt:` with `reminderTime:`
  content = content.replaceAll(RegExp(r'\bremindAt\s*:'), 'reminderTime:');

  // Replace Reminder(...) with caregiverId added.
  content =
      content.replaceAllMapped(RegExp(r'Reminder\s*\([\s\S]*?\)'), (match) {
    var fullMatch = match.group(0)!;
    if (!fullMatch.contains('caregiverId:') &&
        fullMatch.contains('patientId:')) {
      return fullMatch.replaceFirst(
          'patientId:', "caregiverId: '', patientId:");
    }
    return fullMatch;
  });

  if (content != original) {
    file.writeAsStringSync(content);
    print('Fixed $path');
  }
}

void main() {
  var libDir = Directory(r'd:\vscode\GTech\MemoCare\memocare\lib');
  var files = libDir.listSync(recursive: true);
  for (var file in files) {
    if (file is File && file.path.endsWith('.dart')) {
      fixFile(file.path);
    }
  }
}
