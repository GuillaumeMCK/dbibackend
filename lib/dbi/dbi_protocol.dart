import 'dart:convert';
import 'dart:typed_data';

/// Constants of the DBI USB backend protocol: the Switch, running DBI's
/// "Install title from DBIbackend", is the USB device and pulls titles from
/// this app, the host.
abstract final class Dbi {
  static const vendorId = 0x057E;
  static const productId = 0x3000;

  /// Every message starts with a header of this size.
  static const headerSize = 16;

  /// File ranges are streamed in segments of this size.
  static const segmentSize = 0x100000;

  /// Extensions of the titles DBI can install (lowercase).
  static const extensions = {'.nsp', '.nsz', '.xci', '.xcz'};

  static bool isTitle(String path) => switch (path.lastIndexOf('.')) {
    -1 => false,
    final dot => extensions.contains(path.substring(dot).toLowerCase()),
  };
}

enum DbiCommand {
  exit(0),
  listDeprecated(1),
  fileRange(2),
  list(3);

  const DbiCommand(this.id);

  final int id;

  static DbiCommand? fromId(int id) =>
      values.where((command) => command.id == id).firstOrNull;
}

enum DbiCommandType {
  request(0),
  response(1),
  ack(2);

  const DbiCommandType(this.id);

  final int id;
}

/// The 16-byte header of every message: the `DBI0` magic, then the command
/// type, the command id and the size of the data that follows, as
/// little-endian u32.
final class const DbiHeader({
  required final int type,
  required final int commandId,
  final int dataSize = 0,
}) {
  DbiHeader.of(DbiCommandType type, DbiCommand command, [int dataSize = 0])
    : this(type: type.id, commandId: command.id, dataSize: dataSize);

  static const _magic = [0x44, 0x42, 0x49, 0x30]; // DBI0

  /// Parses [bytes], or returns null when they don't start with the magic.
  static DbiHeader? parse(Uint8List bytes) {
    if (bytes.length < Dbi.headerSize) return null;
    for (final (i, byte) in _magic.indexed) {
      if (bytes[i] != byte) return null;
    }
    final data = ByteData.sublistView(bytes);
    return DbiHeader(
      type: data.getUint32(4, .little),
      commandId: data.getUint32(8, .little),
      dataSize: data.getUint32(12, .little),
    );
  }

  DbiCommand? get command => DbiCommand.fromId(commandId);

  Uint8List encode() {
    final bytes = Uint8List(Dbi.headerSize)..setAll(0, _magic);
    ByteData.sublistView(bytes)
      ..setUint32(4, type, .little)
      ..setUint32(8, commandId, .little)
      ..setUint32(12, dataSize, .little);
    return bytes;
  }

  @override
  String toString() =>
      'DbiHeader(type: $type, command: ${command?.name ?? commandId}, '
      'dataSize: $dataSize)';
}

/// The payload of a [DbiCommand.fileRange] request: [size] bytes of the title
/// [name], starting at [offset].
final class const DbiFileRange({
  required final int size,
  required final int offset,
  required final String name,
}) {
  /// Parses `u32 size, u64 offset, u32 nameLength, name`.
  factory DbiFileRange.parse(Uint8List bytes) {
    final data = ByteData.sublistView(bytes);
    final end = (16 + data.getUint32(12, .little)).clamp(16, bytes.length);
    return DbiFileRange(
      size: data.getUint32(0, .little),
      offset: data.getUint64(4, .little),
      name: utf8.decode(bytes.sublist(16, end), allowMalformed: true),
    );
  }

  @override
  String toString() =>
      'DbiFileRange(name: $name, offset: $offset, size: $size)';
}
