import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:usb_host/usb_host.dart';
import 'package:flutter/foundation.dart';

import '/core/logger/logger.dart';
import '/dbi/dbi_protocol.dart';
import '/titles/titles_bloc.dart';
import 'link_state.dart';
import 'link_session.dart';

export 'link_state.dart';

/// The link to the Switch: once titles are queued, checks USB access, waits
/// for a Switch in DBI's backend mode, and serves [TitlesBloc]'s titles over
/// a [LinkSession] until it ends, then waits for the next one.
final class LinkCubit extends Cubit<LinkState> {
  LinkCubit(this._titles) : super(const LinkIdle());

  final TitlesBloc _titles;

  static const _log = kReleaseMode ? null : Logger('LinkCubit');

  static const _selector = DeviceSelector(
    vendorId: Dbi.vendorId,
    productId: Dbi.productId,
  );

  /// Delay before looking for the Switch again once a session ended.
  static const _rescanDelay = Duration(seconds: 1);

  Usb? _usb;
  StreamSubscription<HotplugEvent>? _hotplug;
  Timer? _rescan;

  /// The Switch being connected or served; only one at a time.
  DeviceId? _deviceId;
  LinkSession? _session;

  /// Waits for titles to be queued, then [_watch]es for the Switch.
  Future<void> start() async {
    if (_titles.state.titles.isEmpty) {
      await _titles.stream.firstWhere(
        (titles) => titles.titles.isNotEmpty,
        orElse: () => _titles.state,
      );
    }
    if (!isClosed) await _watch();
  }

  /// Checks USB access, then watches for the Switch.
  Future<void> _watch() async {
    await _hotplug?.cancel();
    emit(const LinkCheckingAccess());
    try {
      final usb = _usb = await Usb.initialize();
      await usb.listDevices();
      emit(const LinkSearching());
      _hotplug = usb
          .watchDevices(includeConnected: true)
          .listen(_onHotplug, onError: _onUsbUnavailable);
    } on Object catch (error, st) {
      _onUsbUnavailable(error, st);
    }
  }

  /// Starts over from the step that failed.
  Future<void> retry() async => switch (state) {
    LinkAccessDenied() => _watch(),
    LinkFailed() => _connectIfPresent(),
    _ => null,
  };

  void _onUsbUnavailable(Object error, StackTrace stackTrace) {
    _log?.error('USB unavailable', error, stackTrace);
    emit(LinkAccessDenied(error));
  }

  void _onHotplug(HotplugEvent event) => switch (event) {
    HotplugConnected(:final device) when device.matches(_selector) => unawaited(
      _connect(device),
    ),
    HotplugDisconnected(:final id) when id == _deviceId => _session?.stop(),
    _ => null,
  };

  Future<void> _connectIfPresent() async {
    if (await _usb?.findDevice(const [_selector]) case final info?) {
      return _connect(info);
    }
    if (state is! LinkSearching) emit(const LinkSearching());
  }

  Future<void> _connect(DeviceInfo info) async {
    if (_deviceId != null || isClosed) return;
    _rescan?.cancel();
    _deviceId = info.id;
    final device = info.productString ?? 'Nintendo Switch';
    emit(LinkConnecting(device));

    Object? failure;
    try {
      final session = _session = await LinkSession.open(info, _titles);
      emit(LinkConnected(device));
      await session.run();
      _log?.info('DBI session ended');
    } on UsbException catch (error, st) {
      _log?.error('Connection to $device lost', error, st);
      if (!_isDisconnect(error)) failure = error;
    } on Object catch (error, st) {
      _log?.error('Connection to $device failed', error, st);
      failure = error;
    } finally {
      _titles.add(const TitlesSessionEnded());
      _session?.dispose();
      _session = null;
      _deviceId = null;
    }

    if (isClosed) return;
    if (failure != null) return emit(LinkFailed(device, failure));
    emit(const LinkSearching());
    // DBI may start a new session without the Switch reconnecting.
    _rescan = Timer(_rescanDelay, _connectIfPresent);
  }

  static bool _isDisconnect(UsbException error) =>
      error.kind == .disconnected || error.kind == .transferDisconnected;

  @override
  Future<void> close() async {
    _rescan?.cancel();
    _session?.stop();
    await _hotplug?.cancel();
    return super.close();
  }
}
