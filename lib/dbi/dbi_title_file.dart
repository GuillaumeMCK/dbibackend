import 'dart:io';
import 'dart:typed_data';

/// A title file kept open across DBI's file ranges, reading one segment ahead.
///
/// DBI reads a title as many consecutive ranges of about a segment each, so
/// the segment after the one just read is read from disk while the current
/// one is on the wire, even across ranges.
final class DbiTitleFile {
  DbiTitleFile._(this.path, this._file, this._segmentSize);

  static Future<DbiTitleFile> open(
    String path, {
    required int segmentSize,
  }) async => DbiTitleFile._(path, await File(path).open(), segmentSize);

  final String path;
  final RandomAccessFile _file;
  final int _segmentSize;

  /// Position of [_file], or null when unknown.
  int? _position = 0;
  ({int offset, Future<Uint8List> bytes})? _ahead;

  /// Reads exactly [length] bytes at [offset], then starts reading the next
  /// segment.
  Future<Uint8List> read(int offset, int length) async {
    final bytes =
        await _takeAhead(offset, length) ?? await _readAt(offset, length);
    if (bytes.length < length) {
      throw FileSystemException('Unexpected end of file', path);
    }
    final next = offset + length;
    // Awaited by the next read or [close]; errors are reported there.
    _ahead = (offset: next, bytes: _readAt(next, _segmentSize)..ignore());
    return bytes.length == length ? bytes : .sublistView(bytes, 0, length);
  }

  /// The segment read ahead if it covers [length] bytes at [offset], or null
  /// once it is done: the file allows one operation at a time.
  Future<Uint8List?> _takeAhead(int offset, int length) async {
    final ahead = _ahead;
    _ahead = null;
    if (ahead == null) return null;
    try {
      final bytes = await ahead.bytes;
      if (ahead.offset == offset && bytes.length >= length) return bytes;
    } on FileSystemException {
      // Read again below, reporting the error if it persists.
    }
    return null;
  }

  Future<Uint8List> _readAt(int offset, int length) async {
    try {
      if (_position != offset) await _file.setPosition(offset);
      final bytes = await _file.read(length);
      _position = offset + bytes.length;
      return bytes;
    } on Object {
      _position = null;
      rethrow;
    }
  }

  Future<void> close() async {
    await _ahead?.bytes.then((_) {}, onError: (_) {});
    _ahead = null;
    await _file.close();
  }
}
