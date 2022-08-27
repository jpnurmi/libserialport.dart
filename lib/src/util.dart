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
import 'package:libserialport/src/bindings.dart';
import 'package:libserialport/src/port.dart';

typedef UtilFunc<T extends ffi.NativeType> = int Function(ffi.Pointer<T> ptr);

// ignore: avoid_classes_with_only_static_members
class Util {
  static int call(int Function() func) {
    final ret = func();
    if (ret < sp_return.SP_OK && SerialPort.lastError!.errorCode != 0) {
      throw SerialPort.lastError!;
    }
    return ret;
  }

  static Uint8List read(int bytes, UtilFunc<ffi.Uint8> readFunc) {
    return ffi.using((arena) {
      final ptr = arena<ffi.Uint8>(bytes);
      final len = call(() => readFunc(ptr));
      return Uint8List.fromList(ptr.asTypedList(len));
    });
  }

  static int write(Uint8List bytes, UtilFunc<ffi.Uint8> writeFunc) {
    return ffi.using((arena) {
      final len = bytes.length;
      final ptr = arena<ffi.Uint8>(len);
      ptr.asTypedList(len).setAll(0, bytes);
      return call(() => writeFunc(ptr));
    });
  }

  static String? fromUtf8(ffi.Pointer<ffi.Char> str) {
    if (str == ffi.nullptr) return null;
    final length = str.cast<ffi.Utf8>().length;
    try {
      return utf8.decode(str.cast<ffi.Uint8>().asTypedList(length));
    } catch (_) {
      return latin1.decode(str.cast<ffi.Uint8>().asTypedList(length));
    }
  }

  static ffi.Pointer<ffi.Char> toUtf8(String str) {
    return str.toNativeUtf8().cast<ffi.Char>();
  }

  static int? getInt(UtilFunc<ffi.Int> getFunc) {
    return ffi.using((arena) {
      final ptr = arena<ffi.Int>();
      final rv = call(() => getFunc(ptr));
      if (rv != sp_return.SP_OK) return null;
      return ptr.value;
    });
  }
}
