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

import 'package:ffi/ffi.dart' as ffi;
import 'package:dart_serial_port/src/bindings.dart';
import 'package:dart_serial_port/src/dylib.dart';
import 'package:dart_serial_port/src/util.dart';

/// Serial port config.
///
/// You should always configure all settings before using a port. There are no
/// default settings applied by the library. When you open a port, it may have
/// default settings from the OS or driver, or the settings left over by the
/// last program to use it.
///
/// You should always set baud rate, data bits, parity and stop bits.
///
/// You should normally also set one of the preset flow control modes, which
/// will set up the RTS, CTS, DTR and DSR pin behaviours and enable or disable
/// XON/XOFF.
///
/// If you need an unusual configuration not covered by the preset flow control
/// modes, you will need to configure these settings individually, and avoid
/// setting flow control which will overwrite these settings.
///
/// @note A port must be opened before you can change its settings.
///
/// Use getters and setters like [baudRate] to get and set individual
/// settings from a configuration.
///
/// For each setting in a port configuration, a special value of -1 can
/// be used, which will cause that setting to be left alone when the
/// configuration is applied by [SerialPort.config] setter.
///
/// This value is also be used for any settings which are not configured
/// at the OS level, or in a state that is not representable within the
/// library API.
///
/// Configurations must be disposed using [dispose()]. When a new
/// configuration is created, all of its settings are initially set to
/// the special -1 value.
///
/// See also:
/// - [SerialPort.config]
abstract class SerialPortConfig {
  /// Creates a serial port configuration.
  ///
  /// @note Call [dispose()] to release the resources after you're done with
  ///       the serial port config.
  factory SerialPortConfig() => _SerialPortConfigImpl();

  /// @internal
  factory SerialPortConfig.fromAddress(int address) =>
      _SerialPortConfigImpl.fromAddress(address);

  /// @internal
  int get address;

  /// Releases all resources associated with the serial port config.
  ///
  /// @note Call this function after you're done with the serial port config.
  void dispose();

  /// Gets the baud rate from the port configuration.
  int get baudRate;

  /// Sets the baud rate in the port configuration.
  set baudRate(int value);

  /// Gets the data bits from the port configuration.
  int get bits;

  /// Sets the data bits in the port configuration.
  set bits(int value);

  /// Gets the parity setting from the port configuration.
  int get parity;

  /// Sets the parity setting in the port configuration.
  set parity(int value);

  /// Gets the stop bits from the port configuration.
  int get stopBits;

  /// Sets the stop bits in the port configuration.
  set stopBits(int value);

  /// Gets the RTS pin behaviour from the port configuration.
  ///
  /// See also:
  /// - [SerialPortRts]
  int get rts;

  /// Sets the RTS pin behaviour in the port configuration.
  ///
  /// See also:
  /// - [SerialPortRts]
  set rts(int value);

  /// Gets the CTS pin behaviour from the port configuration.
  ///
  /// See also:
  /// - [SerialPortCts]
  int get cts;

  /// Sets the CTS pin behaviour in the port configuration.
  ///
  /// See also:
  /// - [SerialPortCts]
  set cts(int value);

  /// Gets the DTR pin behaviour from the port configuration.
  ///
  /// See also:
  /// - [SerialPortDtr]
  int get dtr;

  /// Sets the DTR pin behaviour in the port configuration.
  ///
  /// See also:
  /// - [SerialPortDtr]
  set dtr(int value);

  /// Gets the DSR pin behaviour from the port configuration.
  ///
  /// See also:
  /// - [SerialPortDsr]
  int get dsr;

  /// Sets the DSR pin behaviour in the port configuration.
  ///
  /// See also:
  /// - [SerialPortDsr]
  set dsr(int value);

  /// Gets the XON/XOFF configuration from the port configuration.
  ///
  /// See also:
  /// - [SerialPortXonXoff]
  int get xonXoff;

  /// Sets the XON/XOFF configuration in the port configuration.
  ///
  /// See also:
  /// - [SerialPortXonXoff]
  set xonXoff(int value);

  /// Sets the flow control type in the port configuration.
  ///
  /// This function is a wrapper that sets the RTS, CTS, DTR, DSR and
  /// XON/XOFF settings as necessary for the specified flow control
  /// type. For more fine-grained control of these settings, use their
  /// individual configuration functions.
  ///
  /// See also:
  /// - [SerialPortFlowControl]
  set flowControl(int value);
}

class _SerialPortConfigImpl implements SerialPortConfig {
  final ffi.Pointer<sp_port_config> _config;

  _SerialPortConfigImpl() : _config = _init();
  _SerialPortConfigImpl.fromAddress(int address)
      : _config = ffi.Pointer<sp_port_config>.fromAddress(address);

  @override
  int get address => _config.address;

  static ffi.Pointer<sp_port_config> _init() {
    final out = ffi.allocate<ffi.Pointer<sp_port_config>>();
    Util.call(() => dylib.sp_new_config(out));
    final config = out[0];
    ffi.free(out);
    return config;
  }

  @override
  void dispose() => dylib.sp_free_config(_config);

  @override
  int get baudRate => _get(dylib.sp_get_config_baudrate);
  @override
  set baudRate(int value) => _set(dylib.sp_set_config_baudrate, value);

  @override
  int get bits => _get(dylib.sp_get_config_bits);
  @override
  set bits(int value) => _set(dylib.sp_set_config_bits, value);

  @override
  int get parity => _get(dylib.sp_get_config_parity);
  @override
  set parity(int value) => _set(dylib.sp_set_config_parity, value);

  @override
  int get stopBits => _get(dylib.sp_get_config_stopbits);
  @override
  set stopBits(int value) => _set(dylib.sp_set_config_stopbits, value);

  @override
  int get rts => _get(dylib.sp_get_config_rts);
  @override
  set rts(int value) => _set(dylib.sp_set_config_rts, value);

  @override
  int get cts => _get(dylib.sp_get_config_cts);
  @override
  set cts(int value) => _set(dylib.sp_set_config_cts, value);

  @override
  int get dtr => _get(dylib.sp_get_config_dtr);
  @override
  set dtr(int value) => _set(dylib.sp_set_config_dtr, value);

  @override
  int get dsr => _get(dylib.sp_get_config_dsr);
  @override
  set dsr(int value) => _set(dylib.sp_set_config_dsr, value);

  @override
  int get xonXoff => _get(dylib.sp_get_config_xon_xoff);
  @override
  set xonXoff(int value) => _set(dylib.sp_set_config_xon_xoff, value);

  @override
  set flowControl(int value) => _set(dylib.sp_set_config_flowcontrol, value);

  int _get(Function sp_get_config) {
    return Util.toInt((ptr) {
      return sp_get_config(_config, ptr);
    });
  }

  void _set(Function sp_set_config, int value) {
    Util.call(() => sp_set_config(_config, value));
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) return false;
    _SerialPortConfigImpl config = other;
    return _config == config._config;
  }

  @override
  int get hashCode => _config.hashCode;

  @override
  String toString() => '$runtimeType($_config)';
}
