import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:Floower/ble/ble_provider.dart';
import 'package:Floower/ble/ble_scanner.dart';

class FloowerScanner extends ChangeNotifier {

  final BleProvider bleProvider;
  final Function(DiscoveredDevice) onAutoConnect;
  final Duration autoConnectDelay;

  BleScanner _bleScanner;
  StreamSubscription<BleScannerState> _bleScannerStateSubscription;

  List<DiscoveredDevice> _discoveredDevices = [];
  FloowerScannerState _state = FloowerScannerState.initial;
  String _failedMessage;

  Timer _tryConnectTimer;
  DiscoveredDevice _device;

  FloowerScanner({
    @required this.bleProvider,
    this.onAutoConnect,
    this.autoConnectDelay
  }) : assert(bleProvider != null) {
    _bleScanner = BleScanner(bleProvider);
    _bleScannerStateSubscription = _bleScanner.state.listen(_onScannerState);
  }

  List<DiscoveredDevice> get discoveredDevices {
    return _discoveredDevices;
  }

  FloowerScannerState get state {
    return _state;
  }

  @override
  void dispose() {
    _tryConnectTimer?.cancel();
    _bleScannerStateSubscription?.cancel();
    _bleScanner?.dispose();
    super.dispose();
  }

  void startScanning() {
    assert(bleProvider.status == BleStatus.ready);

    _bleScanner.startScan(
        serviceIds: [],
        timeout: Duration(seconds: 60)
    );
    _tryConnectTimer?.cancel();

    _state = FloowerScannerState.scanning;
    _discoveredDevices = [];
    notifyListeners();
  }

  Future<void> stopScanning() async {
    _tryConnectTimer?.cancel();
    await _bleScanner.stopScan();
    _state = FloowerScannerState.finished;
    notifyListeners();
  }

  void _onScannerState(BleScannerState state) {
    if (_state == FloowerScannerState.scanning) {
      _discoveredDevices = state.discoveredDevices;
      if (state.timeOuted == true) {
        _state = FloowerScannerState.timeouted;
      }
      else if (autoConnectDelay != null && _tryConnectTimer?.isActive != true && _discoveredDevices.isNotEmpty) {
        _tryConnectTimer = Timer(autoConnectDelay, _tryConnect);
      }
      notifyListeners();
    }
  }

  void _tryConnect() {
    if (onAutoConnect != null && _discoveredDevices.length == 1) {
      onAutoConnect(_discoveredDevices[0]);
    }
  }
}

enum FloowerScannerState {
  initial,
  scanning,
  finished,
  timeouted,
  failed
}