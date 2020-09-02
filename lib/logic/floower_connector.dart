import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

class FloowerConnector extends ChangeNotifier {

  final Uuid FLOOWER_SERVICE_UUID = Uuid.parse("28e17913-66c1-475f-a76e-86b5242f4cec");
  final Uuid FLOOWER_COLOR_RGB_WRITE_UUID = Uuid.parse("151a039e-68ee-4009-853d-cd9d271e4a6e"); // 3 bytes (RGB)
  final Uuid FLOOWER_COLOR_RGB_READ_UUID = Uuid.parse("ab130585-2b27-498e-a5a5-019391317350"); // 3 bytes (RGB)

  final FlutterReactiveBle _ble;

  FloowerConnectionState _connectionState = FloowerConnectionState.disconnected;

  DiscoveredDevice _device;
  StreamSubscription<ConnectionStateUpdate> _deviceConnection;
  StreamSubscription<CharacteristicValue> _characteristicValuesSubscription;

  FloowerConnector(this._ble);

  FloowerConnectionState get connectionState {
    return _connectionState;
  }

  DiscoveredDevice get device {
    return _device;
  }

  void sendColor(Color color) async {
    assert(connectionState == FloowerConnectionState.connected);
    print("Sending color");

    // Floower uses RGB (3 bytes)
    List<int> value = List();
    value.add(color.red);
    value.add(color.green);
    value.add(color.blue);

    await _ble.writeCharacteristicWithResponse(QualifiedCharacteristic(
      deviceId: device.id,
      serviceId: FLOOWER_SERVICE_UUID,
      characteristicId: FLOOWER_COLOR_RGB_WRITE_UUID,
      //serviceId: Uuid.parse("6E400001-B5A3-F393-E0A9-E50E24DCCA9E"),
      //characteristicId: Uuid.parse("6E400002-B5A3-F393-E0A9-E50E24DCCA9E")
    ), value: value).then((value) {
      print("Sent color");
    }).catchError((e) {
      // TODO: error handler
      throw e;
    });
  }

  Future<void> connect(DiscoveredDevice device) async {
    await _deviceConnection?.cancel();
    _deviceConnection = _ble
      .connectToDevice(id: device.id, connectionTimeout: Duration(seconds: 30))
      .listen(_onConnectionChanged);

    // TODO: verify is device Floower
    _device = device;
    notifyListeners();
  }

  Future<void> disconnect() async {
    if (_deviceConnection != null) {
      try {
        _connectionState = FloowerConnectionState.disconnecting;
        notifyListeners();
        await _characteristicValuesSubscription?.cancel();
        await _deviceConnection.cancel();
      } on Exception catch (e, _) {
        print("Error disconnecting from a device: $e");
      } finally {
        _device = null;
        _connectionState = FloowerConnectionState.disconnected;
        notifyListeners();
      }
    }
  }

  void _onConnectionChanged(ConnectionStateUpdate stateUpdate) {
    switch (stateUpdate.connectionState) {
      case DeviceConnectionState.connected:
        // TODO: verify is device Floower
        _onDeviceConnected(_device);
        _connectionState = FloowerConnectionState.connected;
        break;

      case DeviceConnectionState.connecting:
        _connectionState = FloowerConnectionState.connecting;
        break;

      case DeviceConnectionState.disconnecting:
        _connectionState = FloowerConnectionState.disconnecting;
        break;

      case DeviceConnectionState.disconnected:
        _connectionState = FloowerConnectionState.disconnected;
        break;
    }
    notifyListeners();
  }

  void _onDeviceConnected(device) async {
    await _characteristicValuesSubscription?.cancel();
    _characteristicValuesSubscription = _ble.characteristicValueStream
        .listen(_onCharacteristicValue);

    /*_ble.subscribeToCharacteristic(QualifiedCharacteristic(
      deviceId: _device.id,
      serviceId: FLOOWER_SERVICE_UUID,
      characteristicId: FLOOWER_COLOR_READ_UUID,
    ));*/

    _ble.readCharacteristic(QualifiedCharacteristic(
      deviceId: device.id,
      serviceId: FLOOWER_SERVICE_UUID,
      characteristicId: FLOOWER_COLOR_RGB_READ_UUID,
    )).then((value) {
      print("Got color");
    }).catchError((e) {
      // TODO: check unknown characteristics
      if (e is GenericFailure<CharacteristicValueUpdateError> && e.code == CharacteristicValueUpdateError.unknown) {
        // TODO: this is not working
        print("Unknown characteristics");
        return;
      }
      throw e;
    });

    print("Connected to device");
  }

  void _onCharacteristicValue(CharacteristicValue characteristicValue) {
    print("Received characteristic value: " + characteristicValue.toString());
  }
}

/// Connection state
enum FloowerConnectionState {
  /// Currently establishing a connection.
  connecting,

  /// Checking if device has Floower API
  validating,

  /// Connection is established.
  connected,

  /// Terminating the connection.
  disconnecting,

  /// Device is disconnected.
  disconnected
}