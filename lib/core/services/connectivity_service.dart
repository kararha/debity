import 'dart:async';
import 'dart:io';

class ConnectivityService {
  ConnectivityService._internal();
  static final ConnectivityService instance = ConnectivityService._internal();

  final StreamController<bool> _controller = StreamController<bool>.broadcast();
  Stream<bool> get onConnectivityChanged => _controller.stream;

  Timer? _monitorTimer;
  bool _lastStatus = true;

  /// One-shot check whether the device can resolve example.com (internet reachable).
  Future<bool> checkConnectivity({Duration timeout = const Duration(seconds: 5)}) async {
    try {
      final result = await InternetAddress.lookup('example.com').timeout(timeout);
      final connected = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      _pushStatusIfChanged(connected);
      return connected;
    } catch (_) {
      _pushStatusIfChanged(false);
      return false;
    }
  }

  void _pushStatusIfChanged(bool status) {
    if (status != _lastStatus) {
      _lastStatus = status;
      _controller.add(status);
    }
  }

  /// Start periodic monitoring of connectivity. Idempotent.
  void startMonitoring({Duration interval = const Duration(seconds: 5)}) {
    _monitorTimer ??= Timer.periodic(interval, (_) async {
      await checkConnectivity();
    });
  }

  void stopMonitoring() {
    _monitorTimer?.cancel();
    _monitorTimer = null;
  }

  void dispose() {
    stopMonitoring();
    _controller.close();
  }
}
