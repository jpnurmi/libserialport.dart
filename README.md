# Dart FFI bindings to libserialport

[![pub](https://img.shields.io/pub/v/libserialport.svg)](https://pub.dev/packages/libserialport)
![CI](https://github.com/jpnurmi/libserialport.dart/workflows/CI/badge.svg)
[![style: lint](https://img.shields.io/badge/style-lint-4BC0F5.svg)](https://pub.dev/packages/lint)
[![license: LGPL3+](https://img.shields.io/badge/license-LGPL3+-magenta.svg)](https://opensource.org/licenses/LGPL-3.0)

| **TIP:** See also [`flutter_libserialport`](https://pub.dev/packages/flutter_libserialport) for automatic building and deploying of libserialport. |
| --- |

This Dart package is based on [`libserialport`](https://sigrok.org/wiki/Libserialport),
which is a minimal C-library created by the [sigrok](https://sigrok.org/) project, and
released under the LGPL3+ license. 

Supported platforms:
- Linux
- macOS
- Windows
- Android

This package uses [dart:ffi](https://dart.dev/guides/libraries/c-interop) to call
`libserialport`'s C APIs, which implies that `libserialport` must be bundled to or deployed
with the host application. It can be tedious to build and deploy `libserialport` on all target
platforms, but in case you are building a Flutter app instead of a pure Dart app, there is
a ready-made drop-in solution called [`flutter_libserialport`](https://pub.dev/packages/flutter_libserialport)
that utilizes Flutter's build system to build and deploy `libserialport` on all supported platforms:

## Usage

```dart
import 'package:libserialport/libserialport.dart';

final name = SerialPort.availablePorts.first;
final port = SerialPort(name);
if (!port.openReadWrite()) {
  print(SerialPort.lastError);
  exit(-1);
}

port.write(/* ... */);

final reader = SerialPortReader(port);
reader.stream.listen((data) {
  print('received: $data');
});
```

To use this package, add `libserialport` as a [dependency in your pubspec.yaml file](https://dart.dev/tools/pub/dependencies).
