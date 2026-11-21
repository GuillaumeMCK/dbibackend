sealed class const LinkState();

/// Waiting for titles to be queued before touching USB.
final class const LinkIdle() extends LinkState;

/// Loading the USB library and listing devices.
final class const LinkCheckingAccess() extends LinkState;

/// USB devices can't be used.
final class const LinkAccessDenied(final Object error) extends LinkState;

/// Waiting for a Switch in DBI's backend mode.
final class const LinkSearching() extends LinkState;

/// Opening and claiming the Switch.
final class const LinkConnecting(final String device) extends LinkState;

/// The Switch was found but couldn't be used.
final class const LinkFailed(final String device, final Object error)
    extends LinkState;

/// Serving DBI's requests.
final class const LinkConnected(final String device) extends LinkState;
