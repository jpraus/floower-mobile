import 'dart:async';

import 'package:Floower/ble/ble_provider.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:meta/meta.dart';

class BleScanner {

  BleScanner(this._bleProvider);

  final BleProvider _bleProvider;
  final StreamController<BleScannerState> _stateStreamController = StreamController();

  Timer _timeoutTimer;
  StreamSubscription _subscription;
  final _devices = <DiscoveredDevice>[];

  Stream<BleScannerState> get state => _stateStreamController.stream;

  void startScan({List<Uuid> serviceIds, Duration timeout}) {
    _devices.clear();
    _subscription?.cancel();
    _subscription = _bleProvider.ble.scanForDevices(withServices: serviceIds).listen((device) {
      if (device.name != null && device.name != "") {
        final knownDeviceIndex = _devices.indexWhere((d) => d.id == device.id);
        if (knownDeviceIndex >= 0) {
          _devices[knownDeviceIndex] = device;
        } else {
          _devices.add(device);
        }
        _pushState();
      }
    });
    _timeoutTimer?.cancel();
    if (timeout != null && timeout.inMilliseconds > 0) {
      _timeoutTimer = Timer(timeout, () {
        _stopScan(timeOuted: true);
      });
    }
    _pushState();
  }

  void _pushState({bool timeOuted = false}) {
    print("_pushState");
    _stateStreamController.add(
      BleScannerState(
        discoveredDevices: _devices,
        scanIsInProgress: _subscription != null,
        timeOuted: timeOuted
      ),
    );
  }

  Future<void> _stopScan({bool timeOuted = false}) async {
    await _subscription?.cancel();
    _subscription = null;
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
    _pushState(timeOuted: timeOuted);
  }

  Future<void> stopScan() async {
    _stopScan();
  }

  Future<void> dispose() async {
    _timeoutTimer?.cancel();
    await _subscription?.cancel();
    await _stateStreamController.close();
  }
}

@immutable
class BleScannerState {
  const BleScannerState({
    @required this.discoveredDevices,
    @required this.scanIsInProgress,
    @required this.timeOuted,
  });

  final List<DiscoveredDevice> discoveredDevices;
  final bool scanIsInProgress;
  final bool timeOuted;
}
