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
import 'dart:io';

import 'package:dart_serial_port/src/bindings.dart';

LibSerialPort _dylib;
LibSerialPort get dylib => _dylib ?? LibSerialPort(LibraryLoader.load());

extension StringWith on String {
  String prefixWith(String prefix) {
    if (isEmpty || startsWith(prefix)) return this;
    return prefix + this;
  }

  String suffixWith(String suffix) {
    if (isEmpty || endsWith(suffix)) return this;
    return this + suffix;
  }
}

class LibraryLoader {
  static String get platformPrefix => Platform.isWindows ? '' : 'lib';

  static String get platformSuffix {
    return Platform.isWindows
        ? '.dll'
        : Platform.isMacOS || Platform.isIOS ? '.dylib' : '.so';
  }

  static String fixupName(String baseName) {
    return baseName.prefixWith(platformPrefix).suffixWith(platformSuffix);
  }

  static String fixupPath(String path) => path.suffixWith('/');

  static bool isFile(String path) {
    return path.isNotEmpty &&
        Directory(path).statSync().type == FileSystemEntityType.file;
  }

  static String resolvePath() {
    final path = String.fromEnvironment('LIBSERIALPORT_PATH');
    if (isFile(path)) return path;
    return fixupPath(path) + fixupName('serialport');
  }

  static ffi.DynamicLibrary load() => ffi.DynamicLibrary.open(resolvePath());
}
