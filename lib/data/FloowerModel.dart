import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

class FloowerModel extends ChangeNotifier {
  final FlutterReactiveBle _ble;

  DiscoveredDevice _device;
  StreamSubscription<ConnectionStateUpdate> _deviceConnection;
  ConnectionStateUpdate _deviceConnectionState;

  Color _color;

  FloowerModel(this._ble);

  Color get color {
    return _color;
  }

  void setColor(Color color) {
    _color = color;
    notifyListeners();
  }

  ConnectionStateUpdate get deviceConnectionState {
    return _deviceConnectionState;
  }

  DiscoveredDevice get device {
    return _device;
  }

  bool isConnected() {
    return _deviceConnectionState != null && _deviceConnectionState.connectionState == DeviceConnectionState.connected;
  }

  Future<void> connect(DiscoveredDevice device) async {
    if (_deviceConnection != null) {
      await _deviceConnection.cancel();
      _deviceConnectionState = null;
    }

    _deviceConnection = _ble
      .connectToDevice(id: device.id)
      .listen((state) {
        _deviceConnectionState = state;
        notifyListeners();
      });

    _device = device;
    notifyListeners();
  }

  Future<void> disconnect() async {
    if (_deviceConnection != null) {
      try {
        _deviceConnectionState = ConnectionStateUpdate(
          connectionState: DeviceConnectionState.disconnecting,
          deviceId: _deviceConnectionState.deviceId,
          failure: null
        );
        notifyListeners();
        await _deviceConnection.cancel();
      } on Exception catch (e, _) {
        print("Error disconnecting from a device: $e");
      } finally {
        _device = null;
        _deviceConnectionState = null;
        notifyListeners();
      }
    }
  }
}