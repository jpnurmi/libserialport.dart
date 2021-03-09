import 'dart:io';
import 'dart:typed_data';

import 'package:dart_serial_port/dart_serial_port.dart';
import 'package:test/test.dart';

const EBUSY = 16; // Device or resource busy

int? get lastError => SerialPort.lastError?.errorCode;
String? get lastReason => SerialPort.lastError?.message;
Matcher get throwsError => throwsA(TypeMatcher<SerialPortError>());

String get unsupported => 'Unsupported platform. The tests require Linux.';
String missing(String dev) => 'Missing /dev/$dev. Please install tty0tty.';

void main() {
  setUp(() {
    // https://github.com/lcgamboa/tty0tty
    expect(Platform.isLinux, isTrue, reason: unsupported);
    expect(File('/dev/tnt0').existsSync(), isTrue, reason: missing('tnt0'));
    expect(File('/dev/tnt1').existsSync(), isTrue, reason: missing('tnt1'));
  });

  test('open & close', () {
    final tnt0 = SerialPort('/dev/tnt0');

    expect(tnt0.openRead(), isTrue, reason: lastReason);
    expect(tnt0.close(), isTrue, reason: lastReason);

    expect(tnt0.openWrite(), isTrue, reason: lastReason);
    expect(tnt0.close(), isTrue, reason: lastReason);

    expect(tnt0.openReadWrite(), isTrue, reason: lastReason);
    expect(tnt0.close(), isTrue, reason: lastReason);
  });

  test('read & write', () {
    final tnt0 = SerialPort('/dev/tnt0');
    final tnt1 = SerialPort('/dev/tnt1');

    expect(tnt0.openRead(), isTrue, reason: lastReason);
    expect(tnt1.openWrite(), isTrue, reason: lastReason);

    final bytes = Uint8List.fromList([1, 2, 3]);
    expect(tnt1.write(bytes), bytes.length);
    expect(tnt0.read(bytes.length), equals(bytes));

    expect(tnt0.close(), isTrue, reason: lastReason);
    expect(tnt1.close(), isTrue, reason: lastReason);
  });

  test('throws', () {
    final tnt0 = SerialPort('/dev/tnt0');
    final tnt1 = SerialPort('/dev/tnt1');

    expect(tnt0.openRead(), isTrue, reason: lastReason);
    expect(tnt1.openWrite(), isTrue, reason: lastReason);

    final bytes = Uint8List.fromList([1, 2, 3]);
    expect(() => tnt0.write(bytes), throwsError);
    expect(() => tnt1.read(bytes.length), throwsError);

    expect(tnt0.close(), isTrue, reason: lastReason);
    expect(tnt1.close(), isTrue, reason: lastReason);
  });

  test('busy', () {
    final tnt0 = SerialPort('/dev/tnt0');

    expect(tnt0.openRead(), isTrue, reason: lastReason);

    expect(tnt0.openRead(), isFalse, reason: lastReason);
    expect(lastError, equals(EBUSY));

    tnt0.close();
  });
}
