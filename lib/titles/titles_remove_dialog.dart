import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '/core/theme/theme.dart';
import '/core/widgets/widgets.dart';
import '/i18n/i18n.g.dart';

/// Asks whether to remove a title from the list (the file stays on disk).
class const TitlesRemoveDialog(final String name) extends HookWidget {
  /// Set by "Don't ask again": titles are then removed without asking, until
  /// the app quits.
  static var skip = false;

  static const _width = 420.0;

  /// Whether [name] should be removed: true right away when [skip] is set.
  static Future<bool> confirm(BuildContext context, String name) async {
    if (skip) return true;
    final confirmed = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: t.removeDialog.cancel,
      barrierColor: Palette.transparent,
      transitionDuration: Duration.zero,
      pageBuilder: (context, _, _) => TitlesRemoveDialog(name),
    );
    return confirmed ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final dontAsk = useState(false);
    void close(bool remove) {
      // Only a confirmed removal stops the next ones from asking.
      if (remove && dontAsk.value) skip = true;
      Navigator.pop(context, remove);
    }

    return Center(
      child: CallbackShortcuts(
        bindings: {
          // Y for Yes, O for Oui.
          const SingleActivator(.keyY): () => close(true),
          const SingleActivator(.keyO): () => close(true),
          const SingleActivator(.keyN): () => close(false),
        },
        // Keeps keyboard focus inside the dialog.
        child: FocusScope(
          child: Container(
            width: _width,
            padding: const .all(12),
            decoration: BoxDecoration(
              color: Palette.background,
              border: .all(color: Palette.white),
            ),
            child: Column(
              mainAxisSize: .min,
              crossAxisAlignment: .stretch,
              children: [
                Padding(
                  padding: Insets.row,
                  child: Text(t.removeDialog.title, style: TextStyles.title),
                ),
                const Rule(color: Palette.white),
                Padding(
                  padding: Insets.row,
                  child: Text(
                    name,
                    maxLines: 2,
                    overflow: .ellipsis,
                    style: TextStyles.accent,
                  ),
                ),
                Padding(
                  padding: Insets.row,
                  child: Text(t.removeDialog.question, style: TextStyles.dim),
                ),
                const SizedBox(height: 8),
                CheckBox(
                  t.removeDialog.dontAsk,
                  value: dontAsk.value,
                  onChanged: (value) => dontAsk.value = value,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: .end,
                  spacing: 8,
                  children: [
                    Button(
                      t.removeDialog.yes,
                      autofocus: true,
                      onPressed: () => close(true),
                    ),
                    Button(t.removeDialog.no, onPressed: () => close(false)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
