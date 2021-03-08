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

import 'dart:convert';
import 'dart:ffi' as ffi;
import 'dart:typed_data';

import 'package:ffi/ffi.dart' as ffi;
import 'package:dart_serial_port/src/bindings.dart';
import 'package:dart_serial_port/src/port.dart';

typedef UtilFunc<T extends ffi.NativeType> = int Function(ffi.Pointer<T> ptr);

class Util {
  static int call(int Function() func) {
    final ret = func();
    if (ret < sp_return.SP_OK && SerialPort.lastError!.errorCode != 0) {
      throw SerialPort.lastError!;
    }
    return ret;
  }

  static Uint8List read(int bytes, UtilFunc<ffi.Uint8> readFunc) {
    final ptr = ffi.calloc<ffi.Uint8>(bytes);
    final len = call(() => readFunc(ptr));
    final res = Uint8List.fromList(ptr.asTypedList(len));
    ffi.calloc.free(ptr);
    return res;
  }

  static int write(Uint8List bytes, UtilFunc<ffi.Uint8> writeFunc) {
    final len = bytes.length;
    final ptr = ffi.calloc<ffi.Uint8>(len);
    ptr.asTypedList(len).setAll(0, bytes);
    final res = call(() => writeFunc(ptr));
    ffi.calloc.free(ptr);
    return res;
  }

  static String? fromUtf8(ffi.Pointer<ffi.Int8> str) {
    if (str == ffi.nullptr) return null;
    final length = ffi.Utf8Pointer(str.cast()).length;
    try {
      return utf8.decode(str.cast<ffi.Uint8>().asTypedList(length));
    } catch (_) {
      return latin1.decode(str.cast<ffi.Uint8>().asTypedList(length));
    }
  }

  static ffi.Pointer<ffi.Int8> toUtf8(String str) {
    return ffi.StringUtf8Pointer(str).toNativeUtf8().cast<ffi.Int8>();
  }

  static int? toInt(UtilFunc<ffi.Int32> getFunc) {
    final ptr = ffi.calloc<ffi.Int32>();
    final rv = call(() => getFunc(ptr));
    final value = ptr.value;
    ffi.calloc.free(ptr);
    if (rv != sp_return.SP_OK) return null;
    return value;
  }
}
