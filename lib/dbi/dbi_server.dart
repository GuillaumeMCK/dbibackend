import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:usb_host/usb_host.dart';
import 'package:flutter/foundation.dart';

import '/core/logger/logger.dart';
import 'dbi_protocol.dart';
import 'dbi_title_file.dart';

/// The titles a [DbiServer] offers to the Switch, and where it reports what it
/// sends.
abstract interface class DbiTitleSource {
  /// Names of the titles to list on the Switch, which just asked for them.
  List<String> listTitles();

  /// Path of the file behind [name], or null when it isn't offered.
  String? pathOf(String name);

  /// Bytes `[start, end)` of [name] were sent.
  void onSent(String name, int start, int end);

  void onFailed(String name, Object error);
}

/// Serves DBI's commands over a claimed interface until the Switch exits, the
/// device goes away or [stop] is called.
///
/// Mirrors the reference `dbibackend`: the Switch drives the exchange, the
/// host only answers.
final class DbiServer {
  DbiServer({
    required EndpointReader reader,
    required EndpointWriter writer,
    required this.titles,
  }) : _reader = reader,
       _writer = writer;

  final EndpointReader _reader;
  final EndpointWriter _writer;
  final DbiTitleSource titles;

  /// Bounds every read so [stop] takes effect while the Switch is idle.
  static const readTimeout = Duration(milliseconds: 500);

  /// Segments in flight on the OUT endpoint while streaming a file range.
  static const transfersInFlight = 4;

  static const _log = kReleaseMode ? null : Logger('DbiServer');

  var _stopped = false;

  /// The title being sent, kept open between its ranges.
  DbiTitleFile? _file;

  void stop() => _stopped = true;

  /// Completes when the Switch sends [DbiCommand.exit] or [stop] is called;
  /// throws a [UsbException] when the device is lost.
  Future<void> run() async {
    _log?.info('Entering command loop');
    try {
      await _serve();
    } finally {
      await _file?.close();
      _file = null;
    }
  }

  Future<void> _serve() async {
    while (!_stopped) {
      final bytes = await _read(Dbi.headerSize);
      if (bytes == null) return;
      final header = DbiHeader.parse(bytes);
      if (header == null) continue;
      _log?.debug('$header');

      switch (header.command) {
        case .list:
          await _list();
        case .fileRange:
          await _fileRange(header.dataSize);
        case .exit:
          _log?.info('Exit');
          return _respond(.exit);
        case .listDeprecated || null:
          _log?.warning('Unknown command id: ${header.commandId}');
          return _respond(.exit);
      }
    }
  }

  Future<void> _list() async {
    final names = titles.listTitles();
    _log?.info('Get list (${names.length} titles)');
    final list = utf8.encode(names.map((name) => '$name\n').join());
    await _respond(.list, list.length);
    // Like the reference backend: an empty list has no data, so DBI sends no
    // ack for it. Waiting for one would swallow its next command.
    if (list.isEmpty) return;
    if (await _read(Dbi.headerSize) == null) return; // Ack.
    await _write(list);
  }

  Future<void> _fileRange(int dataSize) async {
    await _write(DbiHeader.of(.ack, .fileRange, dataSize).encode());
    final payload = await _read(dataSize);
    if (payload == null) return;
    final range = DbiFileRange.parse(payload);
    _log?.debug('$range');

    await _respond(.fileRange, range.size);
    if (await _read(Dbi.headerSize) == null) return; // Ack.

    try {
      await _send(range);
    } on FileSystemException catch (error) {
      // The Switch waits for the whole range, so the session can't recover.
      _log?.error('Failed to read ${range.name}', error);
      titles.onFailed(range.name, error);
      rethrow;
    }
  }

  /// Streams [range] in segments, the next one being read from disk while
  /// the current one is on the wire, and waits for the whole range at the end.
  Future<void> _send(DbiFileRange range) async {
    final file = await _open(range.name);
    var sent = 0;
    while (sent < range.size && !_stopped) {
      final start = range.offset + sent;
      final length = min(range.size - sent, Dbi.segmentSize);
      await _writer.writeAll(await file.read(start, length));
      titles.onSent(range.name, start, start + length);
      sent += length;
    }
    await _writer.flush();
  }

  /// The file behind [name], reusing the one of the previous range.
  Future<DbiTitleFile> _open(String name) async {
    final path =
        titles.pathOf(name) ?? (throw FileSystemException('Not queued', name));
    if (_file case final file? when file.path == path) return file;
    await _file?.close();
    _file = null;
    return _file = await DbiTitleFile.open(path, segmentSize: Dbi.segmentSize);
  }

  Future<void> _respond(DbiCommand command, [int dataSize = 0]) =>
      _write(DbiHeader.of(.response, command, dataSize).encode());

  Future<void> _write(List<int> data) async {
    await _writer.writeAll(data);
    await _writer.flush();
  }

  /// Reads exactly [length] bytes, waiting as long as needed, or returns null
  /// once [stop] is called.
  Future<Uint8List?> _read(int length) async {
    while (!_stopped) {
      try {
        return await _reader.readExact(length);
      } on UsbException catch (error) {
        if (error.kind != .timedOut) rethrow;
      }
    }
    return null;
  }
}
