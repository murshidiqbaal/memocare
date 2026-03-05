import 'dart:io';

void main() {
  final pubCache = Platform.environment['PUB_CACHE'] ??
      (Platform.isWindows
          ? '${Platform.environment['LOCALAPPDATA']}\\Pub\\Cache'
          : '${Platform.environment['HOME']}/.pub-cache');
  print('Pub cache: $pubCache');
  final dir = Directory('$pubCache/hosted/pub.dev');
  if (dir.existsSync()) {
    for (var d in dir.listSync()) {
      if (d is Directory && d.path.contains('local_auth')) {
        print(d.path);
      }
    }
  } else {
    print('dir not found');
  }
}
