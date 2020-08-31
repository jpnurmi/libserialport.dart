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

import 'package:ffi/ffi.dart' as ffi;
import 'package:serial_port/src/bindings.dart';
import 'package:serial_port/src/dylib.dart';
import 'package:serial_port/src/util.dart';

abstract class SerialPortConfig {
  factory SerialPortConfig() => _SerialPortConfigImpl();
  factory SerialPortConfig.fromAddress(int address) =>
      _SerialPortConfigImpl.fromAddress(address);

  int get address;

  void dispose();

  int get baudRate;
  void set baudRate(int value);

  int get bits;
  void set bits(int value);

  int get parity;
  void set parity(int value);

  int get stopBits;
  void set stopBits(int value);

  int get rts;
  void set rts(int value);

  int get cts;
  void set cts(int value);

  int get dtr;
  void set dtr(int value);

  int get dsr;
  void set dsr(int value);
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
  void set baudRate(int value) => _set(dylib.sp_set_config_baudrate, value);

  @override
  int get bits => _get(dylib.sp_get_config_bits);
  @override
  void set bits(int value) => _set(dylib.sp_set_config_bits, value);

  @override
  int get parity => _get(dylib.sp_get_config_parity);
  @override
  void set parity(int value) => _set(dylib.sp_set_config_parity, value);

  @override
  int get stopBits => _get(dylib.sp_get_config_stopbits);
  @override
  void set stopBits(int value) => _set(dylib.sp_set_config_stopbits, value);

  @override
  int get rts => _get(dylib.sp_get_config_rts);
  @override
  void set rts(int value) => _set(dylib.sp_set_config_rts, value);

  @override
  int get cts => _get(dylib.sp_get_config_cts);
  @override
  void set cts(int value) => _set(dylib.sp_set_config_cts, value);

  @override
  int get dtr => _get(dylib.sp_get_config_dtr);
  @override
  void set dtr(int value) => _set(dylib.sp_set_config_dtr, value);

  @override
  int get dsr => _get(dylib.sp_get_config_dsr);
  @override
  void set dsr(int value) => _set(dylib.sp_set_config_dsr, value);

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
