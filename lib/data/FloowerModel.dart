import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

class Debouncer {
  final Duration duration;
  VoidCallback action;
  Timer _timer;

  Debouncer({ this.duration });

  debounce(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(duration, action);
  }
}

class FloowerModel extends ChangeNotifier {

  final Uuid FLOOWER_SERVICE_UUID = Uuid.parse("28e17913-66c1-475f-a76e-86b5242f4cec");
  final Uuid FLOOWER_COLOR_WRITE_UUID = Uuid.parse("151a039e-68ee-4009-853d-cd9d271e4a6e"); // 64 int
  final Uuid FLOOWER_COLOR_READ_UUID = Uuid.parse("ab130585-2b27-498e-a5a5-019391317350"); // 64 int

  final FlutterReactiveBle _ble;

  DiscoveredDevice _device;
  StreamSubscription<ConnectionStateUpdate> _deviceConnection;
  ConnectionStateUpdate _deviceConnectionState;
  StreamSubscription<CharacteristicValue> _characteristicValuesSubscription;

  Debouncer _colorDebouncer = Debouncer(duration: Duration(seconds: 1));
  Color _color;

  FloowerModel(this._ble);

  Color get color {
    return _color;
  }

  void setColor(Color color) {
    _color = color;
    notifyListeners();

    // TODO: throttle
    _colorDebouncer.debounce(() {
      print("Sending color");

      // Floower uses HSB (H = )
      HSVColor hsv = HSVColor.fromColor(color);
      List<int> value = List();
      value.add(hsv.hue.toInt());
      value.add((hsv.saturation * 255).toInt());
      value.add((hsv.value * 255).toInt());

      _ble.writeCharacteristicWithResponse(QualifiedCharacteristic(
        deviceId: device.id,
        serviceId: FLOOWER_SERVICE_UUID,
        characteristicId: FLOOWER_COLOR_WRITE_UUID,
        //serviceId: Uuid.parse("6E400001-B5A3-F393-E0A9-E50E24DCCA9E"),
        //characteristicId: Uuid.parse("6E400002-B5A3-F393-E0A9-E50E24DCCA9E")
      ), value: value).then((value) {
        print("Sent color");
      }).catchError((e) {
        throw e;
      });
    });
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
    await _deviceConnection?.cancel();
    _deviceConnection = _ble
      .connectToDevice(id: device.id, connectionTimeout: Duration(seconds: 30))
      .listen(_onConnectionChanged);

    _device = device;
    notifyListeners();
  }

  Future<void> disconnect() async {
    if (_deviceConnection != null) {
      try {
        // TODO: verify is device Floower
        _deviceConnectionState = ConnectionStateUpdate(
          connectionState: DeviceConnectionState.disconnecting,
          deviceId: _deviceConnectionState.deviceId,
          failure: null
        );
        notifyListeners();
        await _characteristicValuesSubscription?.cancel();
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

  void _onConnectionChanged(ConnectionStateUpdate stateUpdate) {
    if (stateUpdate.connectionState == DeviceConnectionState.connected) {
      _onDeviceConnected(_device);
    }
    _deviceConnectionState = stateUpdate;
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
      characteristicId: FLOOWER_COLOR_READ_UUID,
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