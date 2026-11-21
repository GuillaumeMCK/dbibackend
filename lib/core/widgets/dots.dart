import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '/core/hooks/use_periodic.dart';

/// `.`, `..`, `...` in a loop, for something that is waiting. Always three
/// characters wide so the text around it doesn't move.
class const Dots({super.key, final TextStyle? style}) extends HookWidget {
  static const _interval = Duration(milliseconds: 400);

  @override
  Widget build(BuildContext context) {
    final count = useState(1);
    usePeriodic(_interval, () => count.value = count.value % 3 + 1);
    return Text(('.' * count.value).padRight(1), style: style);
  }
}
