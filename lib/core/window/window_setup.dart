import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:window_manager/window_manager.dart' hide Window;

/// Native setup of the main window.
abstract final class WindowSetup {
  static const minimumSize = Size(560, 420);

  /// Runs before the first frame: opens the window at its minimum size,
  /// centered. Hides the title bar on macOS, keeping its buttons, which
  /// [WindowFrame] makes room for, and on Windows, where [WindowFrame] draws
  /// them. Linux keeps its native title bar.
  static void setUp() {
    final window = WindowManager.instance.getCurrent();
    if (window == null) return;
    if (Platform.isMacOS) {
      window
        ..titleBarStyle = .hidden
        ..isWindowControlButtonsVisible = true;
    } else if (Platform.isWindows) {
      window.titleBarStyle = .hidden;
    }
    final size = minimumSize.toNative();
    window
      ..minimumSize = size
      ..setSize(size, false)
      ..center();
  }
}
