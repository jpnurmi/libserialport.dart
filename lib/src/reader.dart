/*
 * Based on libserialport (https://sigrok.org/wiki/Libserialport).
 *
 * Copyright (C) 2010-2012 Bert Vermeulen <bert@biot.com>
 * Copyright (C) 2010-2015 Uwe Hermann <uwe@hermann-uwe.de>
 * Copyright (C) 2013-2015 Martin Ling <martin-libserialport@earth.li>
 * Copyright (C) 2013 Matthias Heidbrink <m-sigrok@heidbrink.biz>
 * Copyright (C) 2014 Aurelien Jacobs <aurel@gnuage.org>
 * Copyright (C) 2020 J-P Nurmi <jpnurmi@gmail.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as
 * published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import 'dart:async';
import 'dart:ffi' as ffi;
import 'dart:isolate';
import 'dart:typed_data';

import 'package:ffi/ffi.dart' as ffi;
import 'package:dart_serial_port/src/bindings.dart';
import 'package:dart_serial_port/src/dylib.dart';
import 'package:dart_serial_port/src/error.dart';
import 'package:dart_serial_port/src/port.dart';
import 'package:dart_serial_port/src/util.dart';

const int _kReadEvents = sp_event.SP_EVENT_RX_READY | sp_event.SP_EVENT_ERROR;

/// Asynchronous serial port reader.
///
/// Provides a [stream] that can be listened to asynchronously receive data
/// whenever available.
///
/// **Note:** The reader must be closed using [close()] when done with reading.
abstract class SerialPortReader {
  /// Creates a reader for the port.
  factory SerialPortReader(SerialPort port, {int timeout}) =>
      _SerialPortReaderImpl(port, timeout: timeout);

  /// Gets the port the reader operates on.
  SerialPort get port;

  /// Gets a stream of data.
  Stream<Uint8List> get stream;

  /// Closes the stream.
  void close();
}

class _SerialPortReaderArgs {
  final int address;
  final int timeout;
  final SendPort sendPort;
  _SerialPortReaderArgs({this.address, this.timeout, this.sendPort});
}

class _SerialPortReaderImpl implements SerialPortReader {
  final SerialPort _port;
  final int _timeout;
  Isolate _isolate;
  ReceivePort _receiver;
  StreamController<Uint8List> _controller;

  _SerialPortReaderImpl(SerialPort port, {int timeout})
      : _port = port,
        _timeout = timeout ?? 500;

  @override
  SerialPort get port => _port;

  @override
  Stream<Uint8List> get stream {
    _controller ??= StreamController<Uint8List>(
      onListen: _startRead,
      onCancel: _cancelRead,
      onPause: _cancelRead,
      onResume: _startRead,
    );
    return _controller.stream;
  }

  @override
  void close() {
    _controller?.close();
    _controller = null;
  }

  void _startRead() {
    _receiver = ReceivePort();
    _receiver.listen((data) {
      if (data is SerialPortError) {
        _controller.addError(data);
      } else {
        _controller.add(data);
      }
    });
    final args = _SerialPortReaderArgs(
      address: _port.address,
      timeout: _timeout,
      sendPort: _receiver.sendPort,
    );
    Isolate.spawn(
      _waitRead,
      args,
      debugName: toString(),
    ).then((value) => _isolate = value);
  }

  void _cancelRead() {
    _receiver?.close();
    _receiver = null;
    _isolate?.kill();
    _isolate = null;
  }

  static void _waitRead(_SerialPortReaderArgs args) {
    final port = ffi.Pointer<sp_port>.fromAddress(args.address);
    final events = _createEvents(port, _kReadEvents);
    var bytes = 0;
    while (bytes >= 0) {
      bytes = _waitEvents(port, events, args.timeout);
      if (bytes > 0) {
        final data = Util.read(bytes, (ffi.Pointer<ffi.Uint8> ptr) {
          return dylib.sp_nonblocking_read(port, ptr.cast(), bytes);
        });
        args.sendPort.send(data);
      } else if (bytes < 0) {
        args.sendPort.send(SerialPort.lastError);
      }
    }
    _releaseEvents(events);
  }

  static ffi.Pointer<ffi.Pointer<sp_event_set>> _createEvents(
    ffi.Pointer<sp_port> port,
    int mask,
  ) {
    final events = ffi.allocate<ffi.Pointer<sp_event_set>>();
    dylib.sp_new_event_set(events);
    dylib.sp_add_port_events(events.value, port, mask);
    return events;
  }

  static int _waitEvents(
    ffi.Pointer<sp_port> port,
    ffi.Pointer<ffi.Pointer<sp_event_set>> events,
    int timeout,
  ) {
    dylib.sp_wait(events.value, timeout);
    return dylib.sp_input_waiting(port);
  }

  static void _releaseEvents(ffi.Pointer<ffi.Pointer<sp_event_set>> events) {
    dylib.sp_free_event_set(events.value);
  }
}
