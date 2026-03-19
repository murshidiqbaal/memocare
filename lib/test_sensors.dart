import 'package:sensors_plus/sensors_plus.dart';

void main() {
  // Try different variations to see what the analyzer accepts
  try {
    print(userAccelerometerEvents);
  } catch (e) {}
  
  try {
    // print(userAccelerometerEventStream()); // This is what failed in SosService
  } catch (e) {}
}
