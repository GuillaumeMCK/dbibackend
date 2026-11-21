import 'dart:async';

import 'package:flutter_hooks/flutter_hooks.dart';

/// Executes a callback every [duration] period.
void usePeriodic(Duration duration, void Function()? callback) {
  useEffect(() {
    final p = Timer.periodic(duration, (_) => callback?.call());
    return p.cancel;
  }, []);
}
