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

/// Buffer selection.
abstract class SerialPortBuffer {
  /// Input buffer.
  static const int input = 1;

  /// Output buffer.
  static const int output = 2;

  /// Both buffers.
  static const int both = 3;
}

/// CTS pin behaviour.
abstract class SerialPortCts {
  /// Special value to indicate setting should be left alone.
  static const int invalid = -1;

  /// CTS ignored.
  static const int ignore = 0;

  /// CTS used for flow control.
  static const int flowControl = 1;
}

/// DSR pin behaviour.
abstract class SerialPortDsr {
  /// Special value to indicate setting should be left alone.
  static const int invalid = -1;

  /// DSR ignored.
  static const int ignore = 0;

  /// DSR used for flow control.
  static const int flowControl = 1;
}

/// DTR pin behaviour.
abstract class SerialPortDtr {
  /// Special value to indicate setting should be left alone.
  static const int invalid = -1;

  /// DTR off.
  static const int off = 0;

  /// DTR on.
  static const int on = 1;

  /// DTR used for flow control.
  static const int flowControl = 2;
}

/// Port events.
abstract class SerialPortEvent {
  /// Data received and ready to read.
  static const int rxReady = 1;

  /// Ready to transmit new data.
  static const int txReady = 2;

  /// Error occurred.
  static const int error = 4;
}

/// Standard flow control combinations.
abstract class SerialPortFlowControl {
  /// No flow control.
  static const int none = 0;

  /// Software flow control using XON/XOFF characters.
  static const int xonXoff = 1;

  /// Hardware flow control using RTS/CTS signals.
  static const int rtsCts = 2;

  /// Hardware flow control using DTR/DSR signals.
  static const int dtrDsr = 3;
}

/// Port access modes.
abstract class SerialPortMode {
  /// Open port for read access.
  static const int read = 1;

  /// Open port for write access.
  static const int write = 2;

  /// Open port for read and write access. @since 0.1.1
  static const int readWrite = 3;
}

/// Parity settings.
abstract class SerialPortParity {
  /// Special value to indicate setting should be left alone.
  static const int invalid = -1;

  /// No parity.
  static const int none = 0;

  /// Odd parity.
  static const int odd = 1;

  /// Even parity.
  static const int even = 2;

  /// Mark parity.
  static const int mark = 3;

  /// Space parity.
  static const int space = 4;
}

/// RTS pin behaviour.
abstract class SerialPortRts {
  /// Special value to indicate setting should be left alone.
  static const int invalid = -1;

  /// RTS off.
  static const int off = 0;

  /// RTS on.
  static const int on = 1;

  /// RTS used for flow control.
  static const int flowControl = 2;
}

/// Input signals.
abstract class SerialPortSignal {
  /// Clear to send.
  static const int cts = 1;

  /// Data set ready.
  static const int dsr = 2;

  /// Data carrier detect.
  static const int dcd = 4;

  /// Ring indicator.
  static const int ri = 8;
}

/// Transport types.
///
/// @since 0.1.1
abstract class SerialPortTransport {
  /// Native platform serial port. @since 0.1.1
  static const int native = 0;

  /// USB serial port adapter. @since 0.1.1
  static const int usb = 1;

  /// Bluetooth serial port adapter. @since 0.1.1
  static const int bluetooth = 2;
}

/// XON/XOFF flow control behaviour.
abstract class SerialPortXonXoff {
  /// Special value to indicate setting should be left alone.
  static const int invalid = -1;

  /// XON/XOFF disabled.
  static const int disabled = 0;

  /// XON/XOFF enabled for input only.
  static const int input = 1;

  /// XON/XOFF enabled for output only.
  static const int output = 2;

  /// XON/XOFF enabled for input and output.
  static const int inOut = 3;
}
