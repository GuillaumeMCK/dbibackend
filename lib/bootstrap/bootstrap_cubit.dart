import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '/core/logger/logger.dart';
import '/core/window/window_setup.dart';
import 'bootstrap_state.dart';

export 'bootstrap_state.dart';

/// Sets the app up before `runApp`: the native window before the first frame.
final class BootstrapCubit extends Cubit<BootstrapState> {
  BootstrapCubit() : super(const BootstrapInitial());

  static const _log = kReleaseMode ? null : Logger('BootstrapCubit');

  final _watch = Stopwatch();

  Future<void> run(VoidCallback runApp) async {
    if (state is! BootstrapInitial) {
      return _log?.warning('Bootstrap already started');
    }
    _watch.start();
    if (!kReleaseMode) Logger.captureErrors();

    await _step(.window, WindowSetup.setUp);
    runApp();

    _watch.stop();
    _log?.info('Bootstrap took [${_watch.elapsedMilliseconds}ms]');
    if (state is BootstrapError) return;
    emit(BootstrapLoaded(_watch.elapsed));
  }

  Future<void> _step(BootstrapTask task, FutureOr<void> Function() run) async {
    // Once a step has failed, skip the rest instead of hiding its error.
    if (state is BootstrapError) return;
    emit(BootstrapLoading(task));
    try {
      await run();
      _log?.info('[${task.name}] initialized successfully');
    } on Object catch (error, st) {
      _log?.error('[${task.name}] something went wrong', error, st);
      emit(BootstrapError(task));
    }
  }
}
