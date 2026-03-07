import 'dart:io';

void main() async {
  print('Cleaning generator cache...');
  await Process.run('dart', ['run', 'build_runner', 'clean']);

  print('Generating code...');
  await Process.start(
    'dart',
    ['run', 'build_runner', 'build', '--delete-conflicting-outputs'],
    mode: ProcessStartMode.inheritStdio,
  );
}
