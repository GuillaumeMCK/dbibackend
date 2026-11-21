import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// A named console logger, for debug and profile builds only.
///
/// Declare it as `kReleaseMode ? null : Logger('Name')` and call it with
/// `_log?.info(...)`: release builds then compile out every call, including
/// the building of its message.
final class const Logger(final String name) {
  void debug(String message) => _print('DEBUG', message);

  void info(String message) => _print('INFO', message);

  void warning(String message, [Object? error]) =>
      _print('WARNING', message, error);

  void error(String message, [Object? error, StackTrace? stackTrace]) =>
      _print('ERROR', message, error, stackTrace);

  void _print(
    String level,
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    debugPrint('[$level] ($name) $message');
    if (error != null) debugPrint('  $error');
    if (stackTrace != null) debugPrint('$stackTrace');
  }

  /// Logs every uncaught Flutter, platform and bloc error.
  static void captureErrors() {
    const root = Logger('root');
    FlutterError.onError = (details) =>
        root.error('Uncaught Flutter error', details.exception, details.stack);
    PlatformDispatcher.instance.onError = (error, stackTrace) {
      root.error('Uncaught error', error, stackTrace);
      return true;
    };
    Bloc.observer = const _LoggingBlocObserver();
  }
}

final class const _LoggingBlocObserver() extends BlocObserver {
  static const _log = Logger('bloc');

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    _log.error('${bloc.runtimeType} failed', error, stackTrace);
    super.onError(bloc, error, stackTrace);
  }
}
