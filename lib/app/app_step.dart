import '/i18n/i18n.g.dart';
import '/link/link_error.dart';
import '/link/link_state.dart';
import '/titles/titles_state.dart';

/// The steps of an install, in order: titles are queued before USB is used.
enum AppStep {
  titles,
  usb,
  device,
  install;

  String get label => switch (this) {
    titles => t.steps.titles.label,
    usb => t.steps.usb.label,
    device => t.steps.device.label,
    install => t.steps.install.label,
  };
}

/// What a step is busy with, when it has no [AppProgress.status] to show.
enum AppActivity { waiting, sending }

/// The current [step], what happens in it ([status] or [activity], none once
/// it is done), what to do ([hint]) and, when it failed, why ([error]).
final class const AppProgress({
  required final AppStep step,
  required final String hint,
  final String? status,
  final AppActivity? activity,
  final String? error,
}) {
  factory AppProgress.of(TitlesState titles, LinkState link) {
    final steps = t.steps;
    return switch ((titles, link)) {
      (TitlesState(titles: [], scanning: true), _) => AppProgress(
        step: .titles,
        status: steps.titles.scanning,
        hint: steps.titles.scanningHint,
      ),
      (TitlesState(titles: []), _) => AppProgress(
        step: .titles,
        activity: .waiting,
        hint: steps.titles.waitingHint,
      ),
      (_, LinkIdle()) => AppProgress(
        step: .usb,
        activity: .waiting,
        hint: steps.usb.idleHint,
      ),
      (_, LinkCheckingAccess()) => AppProgress(
        step: .usb,
        status: steps.usb.checking,
        hint: steps.usb.checkingHint,
      ),
      (_, LinkAccessDenied(:final error)) => AppProgress(
        step: .usb,
        status: steps.failed,
        hint: steps.usb.deniedHint,
        error: LinkError.describe(error),
      ),
      // DBI only shows up on USB once its backend menu is open.
      (_, LinkSearching()) => AppProgress(
        step: .device,
        activity: .waiting,
        hint: steps.device.searchingHint(menu: steps.menu),
      ),
      (_, LinkConnecting()) => AppProgress(
        step: .device,
        status: steps.device.connecting,
        hint: steps.device.connectingHint,
      ),
      (_, LinkFailed(:final error)) => AppProgress(
        step: .device,
        status: steps.failed,
        hint: steps.device.failedHint,
        error: LinkError.describe(error),
      ),
      (TitlesState(sending: true), LinkConnected()) => AppProgress(
        step: .install,
        activity: .sending,
        hint: steps.install.sendingHint,
      ),
      (TitlesState(outdated: true), LinkConnected()) => AppProgress(
        step: .install,
        status: steps.install.refresh,
        hint: steps.install.refreshHint(menu: steps.menu),
      ),
      (TitlesState(listed: null), LinkConnected()) => AppProgress(
        step: .install,
        activity: .waiting,
        hint: steps.install.listingHint,
      ),
      (TitlesState(:final completed, :final titles), LinkConnected())
          when completed == titles.length =>
        AppProgress(step: .install, hint: steps.install.completeHint),
      (_, LinkConnected()) => AppProgress(
        step: .install,
        hint: steps.install.listedHint,
      ),
    };
  }

  bool get failed => error != null;
}
