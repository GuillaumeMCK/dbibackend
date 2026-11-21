import 'package:flutter/widgets.dart';

import '/app/app.dart';
import '/bootstrap/bootstrap_cubit.dart';
import '/i18n/i18n.g.dart';

Future<void> main() {
  WidgetsFlutterBinding.ensureInitialized();
  LocaleSettings.useDeviceLocaleSync();
  final bootstrap = BootstrapCubit();
  return bootstrap.run(() => runApp(App(bootstrap: bootstrap)));
}
