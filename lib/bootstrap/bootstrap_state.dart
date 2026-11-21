enum BootstrapTask { window }

sealed class const BootstrapState();

final class const BootstrapInitial() extends BootstrapState;

/// Running [task].
final class const BootstrapLoading(final BootstrapTask task)
    extends BootstrapState;

final class const BootstrapLoaded(final Duration elapsed)
    extends BootstrapState;

/// [task] failed; the sequence stopped there.
final class const BootstrapError(final BootstrapTask task)
    extends BootstrapState;
