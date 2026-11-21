import 'dart:io';

import 'package:usb_host/usb_host.dart';

import '/dbi/dbi_protocol.dart';
import '/i18n/i18n.g.dart';

/// Why USB or the Switch can't be used, with the fix where there is one.
abstract final class LinkError {
  static String describe(Object error) => switch (error) {
    UsbException(kind: .permissionDenied) when Platform.isLinux =>
      t.errors.udevRule(device: '${_hex(Dbi.vendorId)}:${_hex(Dbi.productId)}'),
    UsbException(kind: .permissionDenied) => t.errors.permissionDenied,
    UsbException(kind: .busy) => t.errors.busy,
    UsbException(kind: .notFound || .unsupported) when Platform.isWindows =>
      t.errors.winUsb,
    UsbException(:final message) => message,
    _ => '$error',
  };

  static String _hex(int value) => value.toRadixString(16).padLeft(4, '0');
}
