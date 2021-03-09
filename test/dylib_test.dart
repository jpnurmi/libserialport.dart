import 'package:dart_serial_port/dart_serial_port.dart';
import 'package:test/test.dart';

void main() {
  test('load', () {
    expect(SerialPort.availablePorts, isNot(throwsArgumentError));
  });
}
