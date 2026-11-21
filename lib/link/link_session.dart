import 'dart:io';

import 'package:usb_host/usb_host.dart';

import '/dbi/dbi_protocol.dart';
import '/dbi/dbi_server.dart';

/// A claimed Switch serving DBI: owns the device, its interface and the
/// [DbiServer] running over them.
final class LinkSession {
  LinkSession._(this._device, this._interface, this._server);

  /// Opens [info], claims DBI's interface and prepares its server.
  static Future<LinkSession> open(
    DeviceInfo info,
    DbiTitleSource titles,
  ) async {
    final device = await info.open();
    try {
      await _configure(device);
      final interface = await device.detachAndClaimInterface(0);
      return LinkSession._(device, interface, _serve(interface, titles));
    } on Object {
      device.dispose();
      rethrow;
    }
  }

  final Device _device;
  final Interface _interface;
  final DbiServer _server;

  /// Serves DBI until the Switch exits or [stop] is called; throws a
  /// [UsbException] when the device is lost.
  Future<void> run() => _server.run();

  void stop() => _server.stop();

  void dispose() {
    _interface.dispose();
    _device.dispose();
  }

  /// Vendor-class devices can come up unconfigured (not on Windows, where
  /// WinUSB configures them and can't change it).
  static Future<void> _configure(Device device) async {
    if (Platform.isWindows) return;
    try {
      device.activeConfiguration();
    } on UsbException catch (error) {
      if (error.kind != .notConfigured) rethrow;
      await device.setConfiguration(1);
    }
  }

  static DbiServer _serve(Interface interface, DbiTitleSource titles) {
    final endpoints = interface.descriptor?.endpoints ?? const [];
    final (input, output) = (
      endpoints.where((e) => e.address.isIn).firstOrNull,
      endpoints.where((e) => e.address.isOut).firstOrNull,
    );
    if (input == null || output == null) {
      throw const UsbException(
        kind: .notFound,
        message: 'DBI endpoints not found',
      );
    }
    final inEndpoint = interface.endpointIn(input.address.value);
    return DbiServer(
      reader: inEndpoint.reader(
        transferSize: inEndpoint.maxPacketSize * 8,
        readTimeout: DbiServer.readTimeout,
      ),
      writer: interface
          .endpointOut(output.address.value)
          .writer(
            transferSize: Dbi.segmentSize,
            numTransfers: DbiServer.transfersInFlight,
          ),
      titles: titles,
    );
  }
}
