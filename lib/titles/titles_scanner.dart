import 'dart:io';

import 'package:flutter/foundation.dart';

import '/core/logger/logger.dart';
import '/dbi/dbi_protocol.dart';

/// Finds the titles DBI can install among dropped files and directories.
abstract final class TitlesScanner {
  static const _log = kReleaseMode ? null : Logger('TitlesScanner');

  /// Files with a title extension in [paths], and anywhere under the
  /// directories among them.
  static Stream<File> scan(Iterable<String> paths) async* {
    for (final path in paths) {
      switch (await FileSystemEntity.type(path)) {
        case .file when Dbi.isTitle(path):
          yield File(path);
        case .directory:
          yield* Directory(path)
              .list(recursive: true)
              .handleError(
                (Object error) => _log?.warning('Failed to scan $path', error),
              )
              .where((entity) => entity is File && Dbi.isTitle(entity.path))
              .cast<File>();
        default:
          _log?.debug('Ignoring $path');
      }
    }
  }

  /// The name DBI lists [file] under.
  static String nameOf(File file) =>
      file.path.split(Platform.pathSeparator).last;
}
