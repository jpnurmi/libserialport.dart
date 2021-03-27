import 'package:libserialport/libserialport.dart';
import 'package:test/test.dart';

void main() {
  test('load', () {
    expect(SerialPort.availablePorts, isNot(throwsArgumentError));
  });
}
