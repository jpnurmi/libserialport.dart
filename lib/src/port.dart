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

import 'dart:ffi' as ffi;
import 'dart:typed_data';

import 'package:ffi/ffi.dart' as ffi;
import 'package:dart_serial_port/src/bindings.dart';
import 'package:dart_serial_port/src/config.dart';
import 'package:dart_serial_port/src/dylib.dart';
import 'package:dart_serial_port/src/enums.dart';
import 'package:dart_serial_port/src/error.dart';
import 'package:dart_serial_port/src/util.dart';

/// Serial port.
///
/// Provides means to:
///
///   - obtaining a list of serial ports on the system
///   - opening, closing and getting information about ports
///   - signals, modem control lines, breaks, etc.
///   - low-level reading and writing data, and buffer management
///
/// **Note:** The port must be disposed using [dispose()] when done.
///
/// # Error handling
///
/// Serial Port for Dart throws [SerialPortError] in case something goes wrong
/// under the hood in libserialport and it returns an error code:
///
///     final port = SerialPort(...);
///       port.write(...);
///     try {
///     } on SerialPortError catch (e) {
///       print(SerialPort.lastError);
///     }
///
/// The error message is that provided by the OS, using the current language
/// settings. The library does not define its own error codes or messages to
/// accompany other return codes.
///
/// See also:
/// - [SerialPortReader]
/// - [SerialPortConfig]
/// - [SerialPortError]
abstract class SerialPort {
  /// Creates a serial port for `name`.
  ///
  /// **Note:** Call [dispose()] to release the resources after you're done
  ///           with the serial port.
  factory SerialPort(String name) => _SerialPortImpl(name);

  /// @internal
  factory SerialPort.fromAddress(int address) =>
      _SerialPortImpl.fromAddress(address);

  /// @internal
  int get address;

  /// Lists the serial ports available on the system.
  static List<String> get availablePorts => _SerialPortImpl.availablePorts;

  /// Releases all resources associated with the serial port.
  ///
  /// @note Call this function after you're done with the serial port.
  void dispose();

  /// Opens the serial port in the specified `mode`.
  ///
  /// See also:
  /// - [SerialPortMode]
  bool open({int mode});

  /// Opens the serial port for reading only.
  bool openRead();

  /// Opens the serial port for writing only.
  bool openWrite();

  /// Opens the serial port for reading and writing.
  bool openReadWrite();

  /// Closes the serial port.
  bool close();

  /// Gets whether the serial port is open.
  bool get isOpen;

  /// Gets the name of the port.
  ///
  /// The name returned is whatever is normally used to refer to a port on the
  /// current operating system; e.g. for Windows it will usually be a "COMn"
  /// device name, and for Unix it will be a device path beginning with "/dev/".
  String get name;

  /// Gets the description of the port, for presenting to end users.
  String get description;

  /// Gets the transport type used by the port.
  ///
  /// See also:
  /// - [SerialPortTransport]
  int get transport;

  /// Gets the USB bus number of a USB serial adapter port.
  int get busNumber;

  /// Gets the USB device number of a USB serial adapter port.
  int get deviceNumber;

  /// Gets the USB vendor ID of a USB serial adapter port.
  int get vendorId;

  /// Gets the USB Product ID of a USB serial adapter port.
  int get productId;

  /// Get the USB manufacturer of a USB serial adapter port.
  String get manufacturer;

  /// Gets the USB product name of a USB serial adapter port.
  String get productName;

  /// Gets the USB serial number of a USB serial adapter port.
  String get serialNumber;

  /// Gets the MAC address of a Bluetooth serial adapter port.
  String get macAddress;

  /// Gets the current configuration of the serial port.
  SerialPortConfig get config;

  /// Sets the configuration for the serial port.
  ///
  /// For each parameter in the configuration, there is a special value
  /// (usually -1, but see the documentation for each field). These values
  /// will be ignored and the corresponding setting left unchanged on the port.
  ///
  /// Upon errors, the configuration of the serial port is unknown since
  /// partial/incomplete config updates may have happened.
  set config(SerialPortConfig config);

  /// Read data from the serial port.
  ///
  /// The operation attempts to read N `bytes` of data.
  ///
  /// If `timeout` is 0 or greater, the read operation is blocking.
  /// The timeout is specified in milliseconds. Pass 0 to wait infinitely.
  Uint8List read(int bytes, {int timeout = -1});

  /// Write data to the serial port.
  ///
  /// If `timeout` is 0 or greater, the write operation is blocking.
  /// The timeout is specified in milliseconds. Pass 0 to wait infinitely.
  ///
  /// Returns the amount of bytes written.
  int write(Uint8List bytes, {int timeout = -1});

  /// Gets the amount of bytes available for reading.
  int get bytesAvailable;

  /// Gets the amount of bytes waiting to be written.
  int get bytesToWrite;

  /// Flushes serial port buffers. Data in the selected buffer(s) is discarded.
  ///
  /// See also:
  /// - [SerialPortBuffer]
  void flush([int buffers = SerialPortBuffer.both]);

  /// Waits for buffered data to be transmitted.
  void drain();

  /// Gets the status of the control signals for the serial port.
  int get signals;

  /// Puts the port transmit line into the break state.
  bool startBreak();

  /// Takes the port transmit line out of the break state.
  bool endBreak();

  /// Gets the error for a failed operation.
  static SerialPortError get lastError => _SerialPortImpl.lastError;
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
  bool get isOpen {
    final handle = Util.toInt((ptr) {
      return dylib.sp_get_port_handle(_port, ptr.cast());
    });
    return handle > 0;
  }

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

  static SerialPortError get lastError {
    final ptr = dylib.sp_last_error_message();
    final str = Util.fromUtf8(ptr);
    dylib.sp_free_error_message(ptr);
    return SerialPortError(str, dylib.sp_last_error_code());
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
