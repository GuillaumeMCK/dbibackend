import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:window_manager/window_manager.dart' hide Window;

/// Native setup of the main window.
abstract final class WindowSetup {
  static const minimumSize = Size(560, 420);

  /// Runs before the first frame: opens the window at its minimum size,
  /// centered. On macOS, hides the title bar but not its buttons, which
  /// [WindowFrame] makes room for; Windows and Linux keep their native title
  /// bar, as hiding it hides their buttons too.
  static void setUp() {
    final window = WindowManager.instance.getCurrent();
    if (window == null) return;
    if (Platform.isMacOS) {
      window
        ..titleBarStyle = .hidden
        ..isWindowControlButtonsVisible = true;
    }
    final size = minimumSize.toNative();
    window
      ..minimumSize = size
      ..setSize(size, false)
      ..center();
  }
}
