/*
 * This file is based on libserialport (https://sigrok.org/wiki/Libserialport).
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

import 'dart:ffi' as ffi;
import 'dart:io';
import 'dart:typed_data';

import 'package:ffi/ffi.dart' as ffi;
import 'package:serial_port/src/bindings.dart';
import 'package:serial_port/src/config.dart';
import 'package:serial_port/src/dylib.dart';
import 'package:serial_port/src/utf8.dart';
import 'package:meta/meta.dart';

void _sp_call(Function sp_func) {
  if (sp_func() != sp_return.SP_OK) {
    // TODO: SerialPortError
    throw OSError(SerialPort.lastErrorMessage, SerialPort.lastErrorCode);
  }
}

class SerialPort {
  final ffi.Pointer<sp_port> _port;

  SerialPort(String name) : _port = _init(name) {}
  SerialPort.fromNative(this._port);
  ffi.Pointer<sp_port> toNative() => _port;

  static ffi.Pointer<sp_port> _init(String name) {
    final out = ffi.allocate<ffi.Pointer<sp_port>>();
    final cstr = Utf8.toUtf8(name);
    _sp_call(() => dylib.sp_get_port_by_name(cstr, out));
    final port = out[0];
    ffi.free(out);
    ffi.free(cstr);
    return port;
  }

  SerialPort copy() {
    final out = ffi.allocate<ffi.Pointer<sp_port>>();
    _sp_call(() => dylib.sp_copy_port(_port, out));
    final port = SerialPort.fromNative(out[0]);
    ffi.free(out);
    return port;
  }

  static List<String> get availablePorts {
    final out = ffi.allocate<ffi.Pointer<ffi.Pointer<sp_port>>>();
    _sp_call(() => dylib.sp_list_ports(out));
    var i = -1;
    var ports = <String>[];
    final array = out.value;
    while (array[++i].address != 0x0) {
      ports.add(Utf8.fromUtf8(dylib.sp_get_port_name(array[i])));
    }
    dylib.sp_free_port_list(array);
    return ports;
  }

  @mustCallSuper
  void dispose() => dylib.sp_free_port(_port);

  bool open(int mode) => dylib.sp_open(_port, mode) == sp_return.SP_OK;
  bool close() => dylib.sp_close(_port) == sp_return.SP_OK;

  String get name => Utf8.fromUtf8(dylib.sp_get_port_name(_port));
  String get description {
    return Utf8.fromUtf8(dylib.sp_get_port_description(_port));
  }

  int get transport => dylib.sp_get_port_transport(_port);

  int get busNumber {
    final ptr = ffi.allocate<ffi.Int32>();
    _sp_call(() => dylib.sp_get_port_usb_bus_address(_port, ptr, ffi.nullptr));
    final bus = ptr.value;
    ffi.free(ptr);
    return bus;
  }

  int get deviceNumber {
    final ptr = ffi.allocate<ffi.Int32>();
    _sp_call(() => dylib.sp_get_port_usb_bus_address(_port, ffi.nullptr, ptr));
    final address = ptr.value;
    ffi.free(ptr);
    return address;
  }

  int get vendorId {
    final ptr = ffi.allocate<ffi.Int32>();
    _sp_call(() => dylib.sp_get_port_usb_vid_pid(_port, ptr, ffi.nullptr));
    final id = ptr.value;
    ffi.free(ptr);
    return id;
  }

  int get productId {
    final ptr = ffi.allocate<ffi.Int32>();
    _sp_call(() => dylib.sp_get_port_usb_vid_pid(_port, ffi.nullptr, ptr));
    final id = ptr.value;
    ffi.free(ptr);
    return id;
  }

  String get manufacturer {
    return Utf8.fromUtf8(dylib.sp_get_port_usb_manufacturer(_port));
  }

  String get productName {
    return Utf8.fromUtf8(dylib.sp_get_port_usb_product(_port));
  }

  String get serialNumber {
    return Utf8.fromUtf8(dylib.sp_get_port_usb_serial(_port));
  }

  String get macAddress {
    return Utf8.fromUtf8(dylib.sp_get_port_bluetooth_address(_port));
  }

  // ### TODO: disposal
  SerialPortConfig get config {
    final config = ffi.allocate<sp_port_config>();
    _sp_call(() => dylib.sp_get_config(_port, config));
    return SerialPortConfig.fromNative(config);
  }

  void set config(SerialPortConfig config) {
    _sp_call(() => dylib.sp_set_config(_port, config.toNative()));
  }

  Uint8List _read(int bytes, Function reader) {
    final ptr = ffi.allocate<ffi.Uint8>(count: bytes);
    var len = 0;
    _sp_call(() => len = reader(ptr));
    final res = ptr.asTypedList(len).toList();
    ffi.free(ptr);
    return res;
  }

  Future<Uint8List> read(int bytes, {int timeout = 0}) async {
    return _read(bytes, (ffi.Pointer ptr) {
      return dylib.sp_nonblocking_read(_port, ptr, bytes);
    });
  }

  Uint8List readSync(int bytes, {int timeout = 0}) {
    return _read(bytes, (ffi.Pointer ptr) {
      return dylib.sp_blocking_read(_port, ptr, bytes, timeout);
    });
  }

  int _write(Uint8List bytes, Function writer) {
    final len = bytes.length;
    final ptr = ffi.allocate<ffi.Uint8>(count: len);
    ptr.asTypedList(len).setAll(0, bytes);
    var res = 0;
    _sp_call(() => res = writer(ptr));
    ffi.free(ptr);
    return res;
  }

  Future<int> write(Uint8List bytes) async {
    return _write(bytes, (ffi.Pointer ptr) {
      return dylib.sp_nonblocking_write(_port, ptr, bytes.length);
    });
  }

  int writeSync(Uint8List bytes, {int timeout = 0}) {
    return _write(bytes, (ffi.Pointer ptr) {
      return dylib.sp_blocking_write(_port, ptr, bytes.length, timeout);
    });
  }

  int get inputWaiting => dylib.sp_input_waiting(_port);
  int get outputWaiting => dylib.sp_output_waiting(_port);

  void flush(int buffers) => dylib.sp_flush(_port, buffers);
  void drain() => dylib.sp_drain(_port);

  // ### TODO: events

  int get signals {
    final ptr = ffi.allocate<ffi.Int32>();
    _sp_call(() => dylib.sp_get_signals(_port, ptr));
    final value = ptr.value;
    ffi.free(ptr);
    return value;
  }

  bool startBreak() => dylib.sp_start_break(_port) == sp_return.SP_OK;
  bool endBreak() => dylib.sp_end_break(_port) == sp_return.SP_OK;

  static int get lastErrorCode => dylib.sp_last_error_code();

  static String get lastErrorMessage {
    final ptr = dylib.sp_last_error_message();
    final str = Utf8.fromUtf8(ptr);
    dylib.sp_free_error_message(ptr);
    return str;
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) return false;
    SerialPort port = other;
    return _port == port._port;
  }

  @override
  int get hashCode => _port.hashCode;

  @override
  String toString() => '$runtimeType($_port)';
}
