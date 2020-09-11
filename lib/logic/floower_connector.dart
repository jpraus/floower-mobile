import 'dart:async';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_reactive_ble/src/model/write_characteristic_info.dart';

class FloowerConnector extends ChangeNotifier {

  final Uuid FLOOWER_SERVICE_UUID = Uuid.parse("28e17913-66c1-475f-a76e-86b5242f4cec");
  final Uuid FLOOWER_NAME_UUID = Uuid.parse("ab130585-2b27-498e-a5a5-019391317350"); // string
  final Uuid FLOOWER_STATE_UUID = Uuid.parse("ac292c4b-8bd0-439b-9260-2d9526fff89a"); // 4 bytes (open level + R + G + B)
  final Uuid FLOOWER_STATE_CHANGE_UUID = Uuid.parse("11226015-0424-44d3-b854-9fc332756cbf"); // 6 bytes (open level + R + G + B + transition duration + mode)
  final Uuid FLOOWER_COLOR_RGB_UUID = Uuid.parse("151a039e-68ee-4009-853d-cd9d271e4a6e"); // 3 bytes (R + G + B)
  final Uuid FLOOWER_COLORS_SCHEME_UUID = Uuid.parse("7b1e9cff-de97-4273-85e3-fd30bc72e128"); // array of 3 bytes per pre-defined color [(R + G + B), (R +G + B), ..]

  final Uuid UNKNOWN_UUID = Uuid.parse("67789d80-d68b-4afb-af13-28799bad561a");

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

  Future<SendResult> sendState({
      int openLevel,
      Color color,
      Duration duration = const Duration(seconds: 1), // max 25s
    }) async {

    //assert(connectionState == FloowerConnectionState.connected);
    print("Sending state (open level + color)");

    // compute mode
    int mode = 0;
    if (color != null) {
      mode += 1;
    }
    if (openLevel != null) {
      mode += 2;
    }

    // 6 bytes data packet
    List<int> value = List();
    value.add(openLevel ?? 0);
    value.add(color?.red ?? 0);
    value.add(color?.green ?? 0);
    value.add(color?.blue ?? 0);
    value.add((duration.inMilliseconds / 100).round());
    value.add(mode);

    SendResult result = await _ble.writeCharacteristicWithResponse(QualifiedCharacteristic(
      deviceId: device.id,
      serviceId: FLOOWER_SERVICE_UUID,
      characteristicId: FLOOWER_STATE_CHANGE_UUID,
    ), value: value).then((value) {
      return SendResult();
    }).catchError((e) {
      if (e.message is GenericFailure<CharacteristicValueUpdateError> || e.message is GenericFailure<WriteCharacteristicFailure>) {
        return SendResult(success: false, errorMessage: "Not a compatibile device");
      }
      throw e;
    });

    return result;
  }

  void sendColor(Color color) async {
    //assert(connectionState == FloowerConnectionState.connected);
    print("Sending color");

    // Floower uses RGB (3 bytes)
    List<int> value = List();
    value.add(color.red);
    value.add(color.green);
    value.add(color.blue);

    await _ble.writeCharacteristicWithResponse(QualifiedCharacteristic(
      deviceId: device.id,
      serviceId: FLOOWER_SERVICE_UUID,
      characteristicId: FLOOWER_COLOR_RGB_UUID,
    ), value: value).then((value) {
      print("Sent color");
    }).catchError((e) {
      // TODO: error handler
      throw e;
    });
  }

  Future<Color> readColor() async {
    //assert(connectionState == FloowerConnectionState.connected);
    print("Getting color");

    return await _ble.readCharacteristic(QualifiedCharacteristic(
      deviceId: device.id,
      serviceId: FLOOWER_SERVICE_UUID,
      characteristicId: UNKNOWN_UUID
    )).then((value) {
      assert(value.length == 3);
      assert(value[0] >= 0 && value[0] <= 255);
      assert(value[1] >= 0 && value[1] <= 255);
      assert(value[2] >= 0 && value[2] <= 255);

      if (value[0] < 0 || value[0] > 255 || value[1] < 0 || value[1] > 255 || value[2] < 0 || value[2] > 255) {
        throw ValueException("RGB color values our of range");
      }

      print("Got color " + value.toString());
      return Color.fromRGBO(value[0], value[1], value[2], 1);
    }).catchError((e) {
      if (e.message is GenericFailure<CharacteristicValueUpdateError> && e.message.code == CharacteristicValueUpdateError.unknown) {
        // TODO: response
        print("Unknown characteristics");
        return;
      }
      throw e;
    });
  }

  Future<void> connect(DiscoveredDevice device) async {
    await _deviceConnection?.cancel();
    _deviceConnection = _ble
      .connectToDevice(id: device.id, connectionTimeout: Duration(seconds: 30))
      .listen(_onConnectionChanged);

    // TODO: verify device is Floower
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

  void pair() {
    if (_connectionState == FloowerConnectionState.pairing) {
      _connectionState = FloowerConnectionState.connected;
      notifyListeners();
    }
  }

  void _onConnectionChanged(ConnectionStateUpdate stateUpdate) {
    switch (stateUpdate.connectionState) {
      case DeviceConnectionState.connected:
        _connectionState = FloowerConnectionState.pairing;
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
    // TODO: verify device is Floower
    await _characteristicValuesSubscription?.cancel();
    _characteristicValuesSubscription = _ble.characteristicValueStream
        .listen(_onCharacteristicValue);

    _connectionState = FloowerConnectionState.pairing;
    notifyListeners();

    //await sendColor(Colors.yellowAccent);

    /*_ble.subscribeToCharacteristic(QualifiedCharacteristic(
      deviceId: _device.id,
      serviceId: FLOOWER_SERVICE_UUID,
      characteristicId: FLOOWER_COLOR_READ_UUID,
    ));*/

    //await readColor();

    //_connectionState = FloowerConnectionState.connected;
    //notifyListeners();

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
  pairing,

  /// Connection is established.
  connected,

  /// Terminating the connection.
  disconnecting,

  /// Device is disconnected.
  disconnected
}

class ValueException implements Exception {

  String _message;

  ValueException([String message = 'Invalid value']) {
    this._message = message;
  }

  @override
  String toString() {
    return _message;
  }
}

class SendResult {
  final bool success;
  final String errorMessage;

  SendResult({
    this.success = true,
    this.errorMessage
  });
}