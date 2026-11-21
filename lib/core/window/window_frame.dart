import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:window_manager/window_manager.dart';

import 'window_metrics.dart';

/// The chrome of the window: a title bar (hidden in full screen, sized by
/// [WindowMetrics]) above the content. On macOS it holds the native window
/// buttons; on Windows it draws them.
class const WindowFrame({super.key, required final Widget child})
    extends HookWidget {
  static final _metrics = WindowMetrics.current;

  @override
  Widget build(BuildContext context) {
    final window = useMemoized(WindowManager.instance.getCurrent);
    final fullScreen = useState(window?.isFullScreen ?? false);

    useEffect(() {
      final listener = window?.addListener(
        (event) => switch (event) {
          WindowEnteredFullScreenEvent() => fullScreen.value = true,
          WindowExitedFullScreenEvent() => fullScreen.value = false,
          _ => null,
        },
      );
      return () {
        if (listener != null) window?.removeListener(listener);
      };
    }, [window]);

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        if (!fullScreen.value)
          SizedBox(
            height: _metrics.barHeight,
            child: Platform.isWindows
                ? WindowCaption(
                    window: window,
                    brightness: .dark,
                    backgroundColor: const Color(0x00000000),
                  )
                : DragToMoveArea(
                    window: window,
                    child: const SizedBox.expand(),
                  ),
          ),
        Expanded(
          child: GestureDetector(
            behavior: .deferToChild,
            onPanStart: (_) => window?.startDragging(),
            child: child,
          ),
        ),
      ],
    );
  }
}
