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
import 'package:meta/meta.dart';

class SerialPortConfig {
  final ffi.Pointer<sp_port_config> _config;

  SerialPortConfig() : _config = _init();
  SerialPortConfig.fromNative(this._config);
  ffi.Pointer<sp_port_config> toNative() => _config;

  static ffi.Pointer<sp_port_config> _init() {
    final out = ffi.allocate<ffi.Pointer<sp_port_config>>();
    Util.call(() => dylib.sp_new_config(out));
    final config = out[0];
    ffi.free(out);
    return config;
  }

  @mustCallSuper
  void dispose() => dylib.sp_free_config(_config);

  int get baudRate => _sp_get(dylib.sp_get_config_baudrate);
  void set baudRate(int value) => _sp_set(dylib.sp_set_config_baudrate, value);

  int get bits => _sp_get(dylib.sp_get_config_bits);
  void set bits(int value) => _sp_set(dylib.sp_set_config_bits, value);

  int get parity => _sp_get(dylib.sp_get_config_parity);
  void set parity(int value) => _sp_set(dylib.sp_set_config_parity, value);

  int get stopBits => _sp_get(dylib.sp_get_config_stopbits);
  void set stopBits(int value) => _sp_set(dylib.sp_set_config_stopbits, value);

  int get rts => _sp_get(dylib.sp_get_config_rts);
  void set rts(int value) => _sp_set(dylib.sp_set_config_rts, value);

  int get cts => _sp_get(dylib.sp_get_config_cts);
  void set cts(int value) => _sp_set(dylib.sp_set_config_cts, value);

  int get dtr => _sp_get(dylib.sp_get_config_dtr);
  void set dtr(int value) => _sp_set(dylib.sp_set_config_dtr, value);

  int get dsr => _sp_get(dylib.sp_get_config_dsr);
  void set dsr(int value) => _sp_set(dylib.sp_set_config_dsr, value);

  int _sp_get(Function sp_func) {
    final ptr = ffi.allocate<ffi.Int32>();
    Util.call(() => sp_func(_config, ptr));
    final value = ptr.value;
    ffi.free(ptr);
    return value;
  }

  void _sp_set(Function sp_func, int value) {
    Util.call(() => sp_func(_config, value));
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) return false;
    SerialPortConfig config = other;
    return _config == config._config;
  }

  @override
  int get hashCode => _config.hashCode;

  @override
  String toString() => '$runtimeType($_config)';
}
