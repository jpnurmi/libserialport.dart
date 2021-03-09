## [0.1.0] - 2021-03-09

* Upgraded to Dart 2.12.
* Fixed use of empty FFI structs.
* Use `dylib` package for dynamic library loading.

## [0.1.0-nullsafety.1] - 2021-03-08

* Migrated to ffi 1.0.0

## [0.1.0-nullsafety.0] - 2021-01-01

* Migrated to null safety
* Happy New Year!

## [0.0.7] - 2021-01-01

* Fixed product & vendor ID etc. to return null instead of random
  values when the respective libserialport query fails underneath.

## [0.0.6] - 2021-01-01

* Fixed dynamic library lookup caching

## [0.0.5] - 2020-12-17

* Fixed a null pointer dereference in SerialPort.availablePorts
  - Thanks @Coimbra1984!

## [0.0.4+1] - 2020-10-02

* Fixed the example snippet in the README

## [0.0.4] - 2020-10-02

* Added a note about flutter_serial_port "sibling" package

## [0.0.3] - 2020-09-27

* Made SerialPortReader report stream errors
* Added SerialPortReader.port getter
* Added SerialPort.isOpen getter
* Fixed SerialPortReader respect stream pause & resume
* Replaced SerialPort.lastErrorXxx with SerialPort.lastError
* Fixed handling of the LIBSERIALPORT_PATH environment variable
* Fixed error handling for errno=0 type of failures

## [0.0.2] - 2020-09-06

* Fixed a null pointer dereference

## [0.0.1+2] - 2020-09-02

* Example: added missing dispose() call to avoid leaks

## [0.0.1+1] - 2020-09-01

* Address pub.dev score

## [0.0.1] - 2020-09-01

* Initial release
