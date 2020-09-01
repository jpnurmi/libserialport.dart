# Serial Port for Dart

[![pub](https://img.shields.io/pub/v/serial_port.svg)](https://pub.dev/packages/serial_port)
[![license: LGPL3+](https://img.shields.io/badge/license-LGPL3+-magenta.svg)](https://opensource.org/licenses/LGPL-3.0)

Serial Port for Dart is based on [libserialport](https://sigrok.org/wiki/Libserialport),
which is a minimal C-library created by the [sigrok](http://sigrok.org/) projects, and
released under the LGPL3+ license.

## Usage

```dart
import 'package:serial_port/serial_port.dart';

final name = SerialPort.availablePorts.first;
final port = SerialPort(name);
if (!port.openReadWrite()) {
  print('${SerialPort.lastErrorMessage} ${SerialPort.lastErrorCode}');
  exit(-1);
}

port.write(/* ... */);

final reader = SerialPortReader(port);
reader.stream.listen((data) {
  print('received: $data');
});
```

To use this package, add `serial_port` as a [dependency in your pubspec.yaml file](https://dart.dev/tools/pub/dependencies).
