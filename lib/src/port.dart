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
import 'dart:typed_data';

import 'package:ffi/ffi.dart' as ffi;
import 'package:serial_port/serial_port.dart';
import 'package:serial_port/src/bindings.dart';
import 'package:serial_port/src/config.dart';
import 'package:serial_port/src/dylib.dart';
import 'package:serial_port/src/util.dart';

abstract class SerialPort {
  factory SerialPort(String name) => _SerialPortImpl(name);
  factory SerialPort.fromAddress(int address) =>
      _SerialPortImpl.fromAddress(address);
  int get address;

  SerialPort copy();

  static List<String> get availablePorts => _SerialPortImpl.availablePorts;

  void dispose();

  bool open({int mode});
  bool openRead();
  bool openWrite();
  bool openReadWrite();
  bool close();

  String get name;
  String get description;
  int get transport;
  int get busNumber;
  int get deviceNumber;
  int get vendorId;
  int get productId;
  String get manufacturer;
  String get productName;
  String get serialNumber;
  String get macAddress;

  SerialPortConfig get config;
  set config(SerialPortConfig config);

  Uint8List read(int bytes, {int timeout = -1});
  int write(Uint8List bytes, {int timeout = -1});

  int get bytesAvailable;
  int get bytesToWrite;

  void flush([int buffers = SerialPortBuffer.both]);
  void drain();

  int get signals;

  bool startBreak();
  bool endBreak();

  static int get lastErrorCode => _SerialPortImpl.lastErrorCode;
  static String get lastErrorMessage => _SerialPortImpl.lastErrorMessage;
}

class _SerialPortImpl implements SerialPort {
  final ffi.Pointer<sp_port> _port;
  SerialPortConfig _config;

  _SerialPortImpl(String name) : _port = _init(name);
  _SerialPortImpl.fromAddress(int address)
      : _port = ffi.Pointer<sp_port>.fromAddress(address);

  @override
  int get address => _port.address;

  static ffi.Pointer<sp_port> _init(String name) {
    final out = ffi.allocate<ffi.Pointer<sp_port>>();
    final cstr = Util.toUtf8(name);
    Util.call(() => dylib.sp_get_port_by_name(cstr, out));
    final port = out[0];
    ffi.free(out);
    ffi.free(cstr);
    return port;
  }

  @override
  SerialPort copy() {
    final out = ffi.allocate<ffi.Pointer<sp_port>>();
    Util.call(() => dylib.sp_copy_port(_port, out));
    final port = _SerialPortImpl.fromAddress(out[0].address);
    ffi.free(out);
    return port;
  }

  static List<String> get availablePorts {
    final out = ffi.allocate<ffi.Pointer<ffi.Pointer<sp_port>>>();
    Util.call(() => dylib.sp_list_ports(out));
    var i = -1;
    var ports = <String>[];
    final array = out.value;
    while (array[++i].address != 0x0) {
      ports.add(Util.fromUtf8(dylib.sp_get_port_name(array[i])));
    }
    dylib.sp_free_port_list(array);
    return ports;
  }

  @override
  void dispose() {
    _config?.dispose();
    dylib.sp_free_port(_port);
  }

  @override
  bool open({int mode}) => dylib.sp_open(_port, mode) == sp_return.SP_OK;
  @override
  bool openRead() => open(mode: SerialPortMode.read);
  @override
  bool openWrite() => open(mode: SerialPortMode.write);
  @override
  bool openReadWrite() => open(mode: SerialPortMode.readWrite);
  @override
  bool close() => dylib.sp_close(_port) == sp_return.SP_OK;

  @override
  String get name => Util.fromUtf8(dylib.sp_get_port_name(_port));
  @override
  String get description {
    return Util.fromUtf8(dylib.sp_get_port_description(_port));
  }

  @override
  int get transport => dylib.sp_get_port_transport(_port);

  @override
  int get busNumber {
    return Util.toInt((ptr) {
      return dylib.sp_get_port_usb_bus_address(_port, ptr, ffi.nullptr);
    });
  }

  @override
  int get deviceNumber {
    return Util.toInt((ptr) {
      return dylib.sp_get_port_usb_bus_address(_port, ffi.nullptr, ptr);
    });
  }

  @override
  int get vendorId {
    return Util.toInt((ptr) {
      return dylib.sp_get_port_usb_vid_pid(_port, ptr, ffi.nullptr);
    });
  }

  @override
  int get productId {
    return Util.toInt((ptr) {
      return dylib.sp_get_port_usb_vid_pid(_port, ffi.nullptr, ptr);
    });
  }

  @override
  String get manufacturer {
    return Util.fromUtf8(dylib.sp_get_port_usb_manufacturer(_port));
  }

  @override
  String get productName {
    return Util.fromUtf8(dylib.sp_get_port_usb_product(_port));
  }

  @override
  String get serialNumber {
    return Util.fromUtf8(dylib.sp_get_port_usb_serial(_port));
  }

  @override
  String get macAddress {
    return Util.fromUtf8(dylib.sp_get_port_bluetooth_address(_port));
  }

  @override
  SerialPortConfig get config {
    if (_config == null) {
      _config = SerialPortConfig();
      final ptr = ffi.Pointer<sp_port_config>.fromAddress(_config.address);
      Util.call(() => dylib.sp_get_config(_port, ptr));
    }
    return _config;
  }

  @override
  set config(SerialPortConfig config) {
    if (_config != config) {
      _config?.dispose();
    }
    _config = config;
    final ptr = ffi.Pointer<sp_port_config>.fromAddress(config.address);
    Util.call(() => dylib.sp_set_config(_port, ptr));
  }

  @override
  Uint8List read(int bytes, {int timeout = -1}) {
    return Util.read(bytes, (ffi.Pointer<ffi.Uint8> ptr) {
      return timeout < 0
          ? dylib.sp_nonblocking_read(_port, ptr.cast(), bytes)
          : dylib.sp_blocking_read(_port, ptr.cast(), bytes, timeout);
    });
  }

  @override
  int write(Uint8List bytes, {int timeout = -1}) {
    return Util.write(bytes, (ffi.Pointer<ffi.Uint8> ptr) {
      return timeout < 0
          ? dylib.sp_nonblocking_write(_port, ptr.cast(), bytes.length)
          : dylib.sp_blocking_write(_port, ptr.cast(), bytes.length, timeout);
    });
  }

  @override
  int get bytesAvailable => dylib.sp_input_waiting(_port);
  @override
  int get bytesToWrite => dylib.sp_output_waiting(_port);

  @override
  void flush([int buffers = SerialPortBuffer.both]) {
    dylib.sp_flush(_port, buffers);
  }

  @override
  void drain() => dylib.sp_drain(_port);

  @override
  int get signals {
    final ptr = ffi.allocate<ffi.Int32>();
    Util.call(() => dylib.sp_get_signals(_port, ptr));
    final value = ptr.value;
    ffi.free(ptr);
    return value;
  }

  @override
  bool startBreak() => dylib.sp_start_break(_port) == sp_return.SP_OK;
  @override
  bool endBreak() => dylib.sp_end_break(_port) == sp_return.SP_OK;

  static int get lastErrorCode => dylib.sp_last_error_code();

  static String get lastErrorMessage {
    final ptr = dylib.sp_last_error_message();
    final str = Util.fromUtf8(ptr);
    dylib.sp_free_error_message(ptr);
    return str;
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) return false;
    _SerialPortImpl port = other;
    return _port == port._port;
  }

  @override
  int get hashCode => _port.hashCode;

  @override
  String toString() => '$runtimeType($_port)';
}
