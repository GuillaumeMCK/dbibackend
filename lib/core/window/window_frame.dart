import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:window_manager/window_manager.dart';

import 'window_metrics.dart';

/// The chrome of the frameless window: a title bar holding the native window
/// buttons (hidden in full screen) and sized after the OS ([WindowMetrics]),
/// above the content.
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
          DragToMoveArea(
            window: window,
            child: SizedBox(height: _metrics.barHeight),
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
