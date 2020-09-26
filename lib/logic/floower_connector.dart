import 'dart:async';
import 'dart:math';

import 'package:Floower/logic/floower_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_reactive_ble/src/model/write_characteristic_info.dart';

class FloowerConnector extends ChangeNotifier {

  static const int MAX_NAME_LENGTH = 25;
  static const int MAX_SCHEME_COLORS = 10;

  // pre-defined colors, keep in sync with firmware
  static FloowerColor COLOR_RED = FloowerColor.fromHwRGB(156, 0, 0);
  static FloowerColor COLOR_GREEN = FloowerColor.fromHwRGB(40, 178, 0);
  static FloowerColor COLOR_BLUE = FloowerColor.fromHwRGB(0, 65, 178);
  static FloowerColor COLOR_YELLOW = FloowerColor.fromHwRGB(178, 170, 0);
  static FloowerColor COLOR_ORANGE = FloowerColor.fromHwRGB(178, 64, 0);
  static FloowerColor COLOR_WHITE = FloowerColor.fromHwRGB(178, 178, 178);
  static FloowerColor COLOR_PURPLE = FloowerColor.fromHwRGB(148, 0, 178);
  static FloowerColor COLOR_PINK = FloowerColor.fromHwRGB(178, 0, 73);

  static List<FloowerColor> DEFAULT_SCHEME = [
    FloowerConnector.COLOR_WHITE,
    FloowerConnector.COLOR_YELLOW,
    FloowerConnector.COLOR_ORANGE,
    FloowerConnector.COLOR_RED,
    FloowerConnector.COLOR_PINK,
    FloowerConnector.COLOR_PURPLE,
    FloowerConnector.COLOR_BLUE,
    FloowerConnector.COLOR_GREEN,
  ];

  // https://docs.springcard.com/books/SpringCore/Host_interfaces/Physical_and_Transport/Bluetooth/Standard_Services
  // Device Information profile
  final Uuid DEVICE_INFORMATION_UUID = Uuid.parse("180A");
  final Uuid DEVICE_INFORMATION_MODEL_NUMBER_STRING_UUID = Uuid.parse("2A24"); // string
  final Uuid DEVICE_INFORMATION_SERIAL_NUMBER_UUID = Uuid.parse("2A25"); // string
  final Uuid DEVICE_INFORMATION_FIRMWARE_REVISION_UUID = Uuid.parse("2A26"); // string M.mm.bbbbb
  final Uuid DEVICE_INFORMATION_HARDWARE_REVISION_UUID = Uuid.parse("2A27"); // string
  final Uuid DEVICE_INFORMATION_SOFTWARE_REVISION_UUID = Uuid.parse("2A28"); // string M.mm.bbbbb
  final Uuid DEVICE_INFORMATION_MANUFACTURER_NAME_UUID = Uuid.parse("2A29"); // string

  // Battery level profile
  final Uuid BATTERY_UUID = Uuid.parse("180F");
  final Uuid BATTERY_LEVEL_UUID = Uuid.parse("2A19"); // uint8
  final Uuid BATTERY_POWER_STATE_UUID = Uuid.parse("2A1A"); // uint8 of states

  // Floower custom profile
  final Uuid FLOOWER_SERVICE_UUID = Uuid.parse("28e17913-66c1-475f-a76e-86b5242f4cec");
  final Uuid FLOOWER_NAME_UUID = Uuid.parse("ab130585-2b27-498e-a5a5-019391317350"); // string, RW
  final Uuid FLOOWER_STATE_UUID = Uuid.parse("ac292c4b-8bd0-439b-9260-2d9526fff89a"); // 4 bytes (open level + R + G + B), RO
  final Uuid FLOOWER_STATE_CHANGE_UUID = Uuid.parse("11226015-0424-44d3-b854-9fc332756cbf"); // 6 bytes (open level + R + G + B + transition duration + mode), WO
  final Uuid FLOOWER_COLORS_SCHEME_UUID = Uuid.parse("7b1e9cff-de97-4273-85e3-fd30bc72e128"); // array of 3 bytes per pre-defined color [(R + G + B), (R +G + B), ..]
  final Uuid FLOOWER_TOUCH_TRESHOLD_UUID = Uuid.parse("c380596f-10d2-47a7-95af-95835e0361c7"); // touch treshold 1 byte

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

  Future<WriteResult> writeState({
      int openLevel,
      Color color,
      Duration duration = const Duration(seconds: 1), // max 25s
    }) {
    print("Writing state: petals=$openLevel% color=$color duration=$duration");

    // compute mode
    int mode = 0;
    mode += color != null ? 1 : 0;
    mode += openLevel != null ? 2 : 0;

    // 6 bytes data packet
    List<int> value = List();
    value.add(openLevel ?? 0);
    value.add(color?.red ?? 0);
    value.add(color?.green ?? 0);
    value.add(color?.blue ?? 0);
    value.add((duration.inMilliseconds / 100).round());
    value.add(mode);

    return _writeCharacteristic(
        serviceId: FLOOWER_SERVICE_UUID,
        characteristicId: FLOOWER_STATE_CHANGE_UUID,
        value: value,
        allowPairing: true
    );
  }

  Future<WriteResult> writeName(String name) {
    if (name.isEmpty || name.length > MAX_NAME_LENGTH) {
      throw ValueException("Name cannot be empty or longer then $MAX_NAME_LENGTH");
    }

    return _writeCharacteristic(
      serviceId: FLOOWER_SERVICE_UUID,
      characteristicId: FLOOWER_NAME_UUID,
      value: name.codeUnits
    );
  }

  Future<WriteResult> writeTouchTreshold(int touchTreshold) {
    if (touchTreshold < 30 && touchTreshold > 60) {
      throw ValueException("Invalid touch treshold value");
    }

    return _writeCharacteristic(
        serviceId: FLOOWER_SERVICE_UUID,
        characteristicId: FLOOWER_TOUCH_TRESHOLD_UUID,
        value: [touchTreshold]
    );
  }

  Future<WriteResult> writeColorScheme({List<FloowerColor> colorScheme}) {
    List<int> value = colorScheme
      .map((color) => color.hwColor)
      .map((color) => [color.red, color.green, color.blue])
      .expand((color) => color)
      .toList();

    print("Writing color scheme: $value");
    return _writeCharacteristic(
        serviceId: FLOOWER_SERVICE_UUID,
        characteristicId: FLOOWER_COLORS_SCHEME_UUID,
        value: value
    );
  }

  Future<WriteResult> _writeCharacteristic({
    @required Uuid serviceId,
    @required Uuid characteristicId,
    @required List<int> value,
    bool allowPairing = false
  }) {
    assert(connectionState == FloowerConnectionState.connected || (allowPairing && connectionState == FloowerConnectionState.pairing));

    return _ble.writeCharacteristicWithResponse(QualifiedCharacteristic(
      deviceId: device.id,
      serviceId: serviceId,
      characteristicId: characteristicId,
    ), value: value).then((value) {
      return WriteResult();
    }).catchError((e) {
      // TODO: handle errors
      if (e.message is GenericFailure<CharacteristicValueUpdateError> || e.message is GenericFailure<WriteCharacteristicFailure>) {
        return WriteResult(success: false, errorMessage: "Not a compatibile device");
      }
      throw e;
    });
  }

  Future<FloowerState> readState() {
    return _readCharacteristics(
      serviceId: FLOOWER_SERVICE_UUID,
      characteristicId: FLOOWER_STATE_UUID,
      allowPairing: true
    ).then((value) {
      assert(value.length == 4);
      assert(value[0] >= 0 && value[0] <= 100); // open level
      assert(value[1] >= 0 && value[1] <= 255); // R
      assert(value[2] >= 0 && value[2] <= 255); // G
      assert(value[3] >= 0 && value[3] <= 255); // B

      if (value[0] < 0 || value[0] > 100) {
        throw ValueException("Petals open level value out of range");
      }
      if (value[1] < 0 || value[1] > 255 || value[2] < 0 || value[2] > 255 || value[3] < 0 || value[3] > 255) {
        throw ValueException("RGB color values out of range");
      }

      print("Got state $value");
      return FloowerState(
        petalsOpenLevel: value[0],
        color: Color.fromRGBO(value[0], value[1], value[2], 1),
      );
    });
  }

  Future<String> readName() {
    return _readCharacteristics(
      serviceId: FLOOWER_SERVICE_UUID,
      characteristicId: FLOOWER_NAME_UUID
    ).then((value) {
      String name = String.fromCharCodes(value);
      print("Got name '$name'");
      return name;
    });
  }

  Future<int> readTouchTreshold() {
    return _readCharacteristics(
        serviceId: FLOOWER_SERVICE_UUID,
        characteristicId: FLOOWER_TOUCH_TRESHOLD_UUID
    ).then((value) {
      int touchTreshold = value[0];
      print("Got touch treshold '$touchTreshold'");
      return touchTreshold;
    });
  }

  Future<String> readModelName() {
    return _readCharacteristics(
        serviceId: DEVICE_INFORMATION_UUID,
        characteristicId: DEVICE_INFORMATION_MODEL_NUMBER_STRING_UUID
    ).then((value) {
      String modelName = String.fromCharCodes(value);
      print("Got model name '$modelName'");
      return modelName;
    });
  }

  Future<int> readSerialNumber() {
    return _readCharacteristics(
        serviceId: DEVICE_INFORMATION_UUID,
        characteristicId: DEVICE_INFORMATION_SERIAL_NUMBER_UUID
    ).then((value) {
      int serialNumber = int.tryParse(String.fromCharCodes(value));
      print("Got serial number '$serialNumber'");
      return serialNumber;
    });
  }

  Future<int> readHardwareRevision() {
    return _readCharacteristics(
        serviceId: DEVICE_INFORMATION_UUID,
        characteristicId: DEVICE_INFORMATION_HARDWARE_REVISION_UUID
    ).then((value) {
      int hardwareRevision = int.tryParse(String.fromCharCodes(value));
      print("Got hardware revision '$hardwareRevision'");
      return hardwareRevision;
    });
  }

  Future<int> readFirmwareVersion() {
    return _readCharacteristics(
        serviceId: DEVICE_INFORMATION_UUID,
        characteristicId: DEVICE_INFORMATION_FIRMWARE_REVISION_UUID
    ).then((value) {
      int firmwareVersion = int.tryParse(String.fromCharCodes(value));
      print("Got firmware version '$firmwareVersion'");
      return firmwareVersion;
    });
  }

  Future<List<Color>> readColorsScheme() {
    return _readCharacteristics(
        serviceId: FLOOWER_SERVICE_UUID,
        characteristicId: FLOOWER_COLORS_SCHEME_UUID
    ).then((value) {
      assert(value.length % 3 == 0);
      for (int byte in value) {
        if (byte < 0 || byte > 255) {
          throw ValueException("RGB color values out of range");
        }
      }
      print("Got colors scheme " + value.toString());
      int count = (value.length / 3).floor();
      List<Color> colors = [];
      for (int c = 0; c < count; c++) {
        int byte = c * 3;
        colors.add(Color.fromRGBO(value[byte], value[byte + 1], value[byte + 2], 1));
      }
      return colors;
    });
  }

  Future<List<int>> _readCharacteristics({
    @required Uuid serviceId,
    @required Uuid characteristicId,
    bool allowPairing = false
  }) {
    assert(connectionState == FloowerConnectionState.connected || (allowPairing && connectionState == FloowerConnectionState.pairing));

    return _ble.readCharacteristic(QualifiedCharacteristic(
        deviceId: device.id,
        serviceId: serviceId,
        characteristicId: characteristicId
    )).catchError((e) {
      // TODO: handle errors
      //if (e.message is GenericFailure<CharacteristicValueUpdateError> && e.message.code == CharacteristicValueUpdateError.unknown) {
      // TODO: response
      //print("Unknown characteristics");
      //}
      throw e;
    });
  }

  Stream<int> subscribeBatteryLevel() {
    assert(connectionState == FloowerConnectionState.connected || connectionState == FloowerConnectionState.pairing);

    // TODO: handle errors
    return _ble.subscribeToCharacteristic(QualifiedCharacteristic(
      deviceId: _device.id,
      serviceId: BATTERY_UUID,
      characteristicId: BATTERY_LEVEL_UUID,
    )).map((bytes) {
      print("Got battery level notification $bytes");
      if (bytes.length == 1) {
        int level = bytes[0];
        if (level < 0) {
          return 0;
        }
        if (level > 100) {
          return 100;
        }
        return level;
      }
      return -1; // unknown
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

class FloowerState {
  final int petalsOpenLevel;
  final Color color;

  FloowerState({this.petalsOpenLevel, this.color});
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

class WriteResult {
  final bool success;
  final String errorMessage;

  WriteResult({
    this.success = true,
    this.errorMessage
  });
}