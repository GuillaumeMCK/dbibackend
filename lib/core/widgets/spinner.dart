import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '/core/hooks/use_periodic.dart';

/// `|`, `/`, `-`, `\` in a loop, for something in progress.
class const Spinner({super.key, final TextStyle? style}) extends HookWidget {
  static const _frames = r'|/-\';
  static const _interval = Duration(milliseconds: 100);

  @override
  Widget build(BuildContext context) {
    final frame = useState(0);
    usePeriodic(_interval, () => frame.value = (frame.value + 1) % 4);
    return Text(_frames[frame.value], style: style);
  }
}
