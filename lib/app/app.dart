import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '/bootstrap/bootstrap_cubit.dart';
import '/bootstrap/bootstrap_view.dart';
import '/core/theme/theme.dart';
import '/core/window/window_frame.dart';
import '/i18n/i18n.g.dart';
import '/link/link_cubit.dart';
import '/titles/titles_bloc.dart';
import 'app_page.dart';

class const App({super.key, required final BootstrapCubit bootstrap})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => MultiBlocProvider(
    providers: [
      BlocProvider.value(value: bootstrap),
      BlocProvider(create: (context) => TitlesBloc()),
      BlocProvider(
        create: (context) => LinkCubit(context.read<TitlesBloc>())..start(),
      ),
    ],
    child: WidgetsApp(
      onGenerateTitle: (context) => t.app.title,
      locale: LocaleSettings.currentLocale.flutterLocale,
      supportedLocales: AppLocaleUtils.supportedLocales,
      color: Palette.background,
      debugShowCheckedModeBanner: false,
      pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
        settings: settings,
        pageBuilder: (context, _, _) => builder(context),
      ),
      home: const _AppContent(),
      // The window chrome wraps the navigator, so dialogs open inside it.
      builder: (context, navigator) => ColoredBox(
        color: Palette.background,
        child: DefaultTextStyle(
          style: TextStyles.body,
          child: WindowFrame(child: navigator!),
        ),
      ),
    ),
  );
}

/// The bootstrap until it is done, then the installer.
class const _AppContent() extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      switch (context.watch<BootstrapCubit>().state) {
        BootstrapLoaded() => const AppPage(),
        _ => const BootstrapView(),
      };
}
