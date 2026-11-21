import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:nativeapi_flutter/nativeapi_flutter.dart' show DropRegion;

import '/core/widgets/widgets.dart';
import '/titles/titles_bloc.dart';
import '/titles/titles_view.dart';
import 'app_footer.dart';

/// The installer: the queued titles, with the current step of the install in
/// the footer. Files and folders can be dropped anywhere on the window, except
/// while titles are being sent.
class const AppPage({super.key}) extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final dragging = useState(false);
    final locked = context.select<TitlesBloc, bool>(
      (titles) => titles.state.sending,
    );
    return DropRegion(
      onDragEntered: (_) => dragging.value = !locked,
      onDragExited: () => dragging.value = false,
      onDropped: (details) {
        dragging.value = false;
        if (locked) return;
        context.read<TitlesBloc>().add(TitlesAdded(details.filePaths));
      },
      // Escape drops the keyboard focus (and its highlight). Dialogs are
      // routes of their own, so Escape still closes them.
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(.escape): () =>
              FocusManager.instance.primaryFocus?.unfocus(),
        },
        child: Padding(
          padding: const .fromLTRB(16, 8, 16, 12),
          child: Column(
            crossAxisAlignment: .stretch,
            children: [
              Expanded(child: TitlesView(dragging: dragging.value)),
              const Rule(),
              const AppFooter(),
            ],
          ),
        ),
      ),
    );
  }
}
