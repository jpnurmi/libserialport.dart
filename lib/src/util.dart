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
import 'package:dart_serial_port/src/port.dart';

typedef UtilFunc<T extends ffi.NativeType> = int Function(ffi.Pointer<T> ptr);

class Util {
  static void call(Function func) {
    if (func() < sp_return.SP_OK && SerialPort.lastError.errorCode != 0) {
      throw SerialPort.lastError;
    }
  }

  static Uint8List read(int bytes, UtilFunc<ffi.Uint8> readFunc) {
    final ptr = ffi.allocate<ffi.Uint8>(count: bytes);
    var len = 0;
    call(() => len = readFunc(ptr));
    final res = Uint8List.fromList(ptr.asTypedList(len));
    ffi.free(ptr);
    return res;
  }

  static int write(Uint8List bytes, UtilFunc<ffi.Uint8> writeFunc) {
    final len = bytes.length;
    final ptr = ffi.allocate<ffi.Uint8>(count: len);
    ptr.asTypedList(len).setAll(0, bytes);
    var res = 0;
    call(() => res = writeFunc(ptr));
    ffi.free(ptr);
    return res;
  }

  static String fromUtf8(ffi.Pointer<ffi.Int8> str) {
    if (str.address == 0x0) return null;
    return ffi.Utf8.fromUtf8(str.cast<ffi.Utf8>());
  }

  static ffi.Pointer<ffi.Int8> toUtf8(String str) {
    return ffi.Utf8.toUtf8(str).cast<ffi.Int8>();
  }

  static int toInt(UtilFunc<ffi.Int32> getFunc) {
    final ptr = ffi.allocate<ffi.Int32>();
    call(() => getFunc(ptr));
    final value = ptr.value;
    ffi.free(ptr);
    return value;
  }
}
