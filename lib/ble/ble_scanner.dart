import 'dart:async';

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:meta/meta.dart';

class BleScanner {
  // TODO: move somewhere
  Uuid floowerService = Uuid.parse('28e17913-66c1-475f-a76e-86b5242f4cec'); // Floower UUID

  BleScanner(this._ble);

  final FlutterReactiveBle _ble;
  final StreamController<BleScannerState> _stateStreamController = StreamController();

  Timer _timeoutTimer;
  StreamSubscription _subscription;
  final _devices = <DiscoveredDevice>[];

  Stream<BleScannerState> get state => _stateStreamController.stream;

  void startScan({List<Uuid> serviceIds, Duration timeout}) {
    _devices.clear();
    _subscription?.cancel();
    _subscription = _ble.scanForDevices(withServices: serviceIds).listen((device) {
      final knownDeviceIndex = _devices.indexWhere((d) => d.id == device.id);
      print('Device discovered: ' + device.name);
      if (knownDeviceIndex >= 0) {
        _devices[knownDeviceIndex] = device;
      } else {
        _devices.add(device);
      }
      _pushState();
    });
    _timeoutTimer?.cancel();
    if (timeout.inMilliseconds > 0) {
      _timeoutTimer = Timer(timeout, () {
        stopScan();
      });
    }
    _pushState();
  }

  void _pushState() {
    _stateStreamController.add(
      BleScannerState(
        discoveredDevices: _devices,
        scanIsInProgress: _subscription != null,
      ),
    );
  }

  Future<void> stopScan() async {
    await _subscription?.cancel();
    _subscription = null;
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
    _pushState();
  }

  Future<void> dispose() async {
    await _stateStreamController.close();
  }
}

@immutable
class BleScannerState {
  const BleScannerState({
    @required this.discoveredDevices,
    @required this.scanIsInProgress,
  });

  final List<DiscoveredDevice> discoveredDevices;
  final bool scanIsInProgress;
}
