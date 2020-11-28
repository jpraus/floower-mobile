import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_reactive_ble/src/model/write_characteristic_info.dart';
import 'package:Floower/ble/ble_provider.dart';
import 'package:Floower/logic/floower_color.dart';

enum FloowerConnectionState {
  connecting, // Currently establishing a connection.
  connected, // Connected to device, API not verified, need to pair
  pairing, // Floower API check waiting for visual verification.
  paired, // Connection is established and verified.
  disconnecting, // Terminating the connection.
  disconnected // Device is disconnected.
}

class FloowerState {
  final int petalsOpenLevel;
  final Color color;

  FloowerState({this.petalsOpenLevel, this.color});
}

class WriteResult {
  final bool success;
  final String errorMessage;

  WriteResult({
    this.success = true,
    this.errorMessage
  });
}

abstract class FloowerConnector extends ChangeNotifier {

  static const int MAX_NAME_LENGTH = 25;
  static const int MAX_SCHEME_COLORS = 10;

  FloowerConnectionState get state;

  Future<WriteResult> writeState({
    int openLevel,
    Color color,
    Duration duration = const Duration(seconds: 1), // max 25s
  });

  Future<WriteResult> writeName(String name);

  Future<WriteResult> writeTouchThreshold(int touchThreshold);

  Future<WriteResult> writeColorScheme({List<Color> colorScheme});

  Future<FloowerState> readState();

  Future<String> readName();

  Future<int> readTouchThreshold();

  Future<String> readModelName();

  Future<int> readSerialNumber();

  Future<int> readHardwareRevision();

  Future<int> readFirmwareVersion();

  Future<List<Color>> readColorsScheme();

  Stream<int> subscribeBatteryLevel();

  Future<void> disconnect();
}

class FloowerConnectorBle extends FloowerConnector {

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
  final Uuid FLOOWER_TOUCH_THRESHOLD_UUID = Uuid.parse("c380596f-10d2-47a7-95af-95835e0361c7"); // touch threshold 1 byte

  final BleProvider _bleProvider;

  FloowerConnectionState _connectionState = FloowerConnectionState.disconnected;
  String _connectionFailureMessage;
  bool _awaitConnectingStart;
  Color _pairingColor;

  String _deviceId;
  StreamSubscription<ConnectionStateUpdate> _deviceConnection;
  StreamSubscription<CharacteristicValue> _characteristicValuesSubscription;

  FloowerConnectorBle(this._bleProvider);

  @override
  FloowerConnectionState get state => _connectionState;

  String get connectionFailureMessage => _connectionFailureMessage;
  String get deviceId => _deviceId;

  @override
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

  @override
  Future<WriteResult> writeName(String name) {
    if (name.isEmpty || name.length > FloowerConnector.MAX_NAME_LENGTH) {
      throw ValueException("Name cannot be empty or longer then ${FloowerConnector.MAX_NAME_LENGTH}");
    }

    return _writeCharacteristic(
        serviceId: FLOOWER_SERVICE_UUID,
        characteristicId: FLOOWER_NAME_UUID,
        value: name.codeUnits
    );
  }

  @override
  Future<WriteResult> writeTouchThreshold(int touchThreshold) {
    if (touchThreshold < 30 && touchThreshold > 60) {
      throw ValueException("Invalid touch threshold value");
    }

    return _writeCharacteristic(
        serviceId: FLOOWER_SERVICE_UUID,
        characteristicId: FLOOWER_TOUCH_THRESHOLD_UUID,
        value: [touchThreshold]
    );
  }

  @override
  Future<WriteResult> writeColorScheme({List<Color> colorScheme}) {
    List<int> value = colorScheme
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
    assert(_connectionState == FloowerConnectionState.paired || (allowPairing && (_connectionState == FloowerConnectionState.connected || _connectionState == FloowerConnectionState.pairing)));

    return _bleProvider.ble.writeCharacteristicWithResponse(QualifiedCharacteristic(
      deviceId: _deviceId,
      serviceId: serviceId,
      characteristicId: characteristicId,
    ), value: value).then((value) {
      return WriteResult();
    }).catchError((e) {
      // TODO: handle errors
      if (e.message is GenericFailure<CharacteristicValueUpdateError> || e.message is GenericFailure<WriteCharacteristicFailure>) {
        return WriteResult(success: false, errorMessage: "Not a compatibile device");
      }
      print("Unhandled write error");
      throw e;
    });
  }

  @override
  Future<FloowerState> readState() {
    return _readCharacteristics(
        serviceId: FLOOWER_SERVICE_UUID,
        characteristicId: FLOOWER_STATE_UUID,
        allowPairing: true
    ).then((value) {
      print(value);
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

  @override
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

  @override
  Future<int> readTouchThreshold() {
    return _readCharacteristics(
        serviceId: FLOOWER_SERVICE_UUID,
        characteristicId: FLOOWER_TOUCH_THRESHOLD_UUID
    ).then((value) {
      int touchThreshold = value[0];
      print("Got touch threshold '$touchThreshold'");
      return touchThreshold;
    });
  }

  @override
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

  @override
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

  @override
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

  @override
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

  @override
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
      print("Got colors scheme ${value.toString()}");
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
    assert(_connectionState == FloowerConnectionState.paired || (allowPairing && (_connectionState == FloowerConnectionState.connected || _connectionState == FloowerConnectionState.pairing)));

    return _bleProvider.ble.readCharacteristic(QualifiedCharacteristic(
        deviceId: _deviceId,
        serviceId: serviceId,
        characteristicId: characteristicId
    )).catchError((e) {
      // TODO: handle errors
      //if (e.message is GenericFailure<CharacteristicValueUpdateError> && e.message.code == CharacteristicValueUpdateError.unknown) {
      // TODO: response
      //print("Unknown characteristics");
      //}
      print("Unhandled read error");
      throw e;
    });
  }

  @override
  Stream<int> subscribeBatteryLevel() {
    assert(_connectionState == FloowerConnectionState.paired || _connectionState == FloowerConnectionState.pairing);

    // TODO: handle errors
    return _bleProvider.ble.subscribeToCharacteristic(QualifiedCharacteristic(
      deviceId: _deviceId,
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

  Future<void> connect(String deviceId, {
    Color pairingColor
  }) async {
    _awaitConnectingStart = true;
    _connectionState = FloowerConnectionState.connecting;

    await _deviceConnection?.cancel();
    _deviceConnection = _bleProvider.ble
        .connectToDevice(id: deviceId, connectionTimeout: Duration(seconds: 30))
        .listen(_onConnectionChanged);

    _pairingColor = pairingColor;
    _deviceId = deviceId;
    notifyListeners();
  }

  @override
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
        _deviceId = null;
        _deviceConnection = null;
        _connectionState = FloowerConnectionState.disconnected;
        notifyListeners();
      }
    }
  }

  void _onConnectionChanged(ConnectionStateUpdate stateUpdate) {
    print("Connection update: ${stateUpdate.connectionState} ($_awaitConnectingStart)");
    if (_awaitConnectingStart && stateUpdate.connectionState == DeviceConnectionState.connecting) {
      _awaitConnectingStart = false;
    }
    if (!_awaitConnectingStart) { // prevent updates while waiting for connecting to start
      _awaitConnectingStart = false;
      switch (stateUpdate.connectionState) {
        case DeviceConnectionState.connected:
          if (_pairingColor == null) {
            _connectionState = FloowerConnectionState.paired;
          }
          else {
            _connectionState = FloowerConnectionState.connected;
            _pair();
          }
          break;

        case DeviceConnectionState.connecting:
          _connectionState = FloowerConnectionState.connecting;
          break;

        case DeviceConnectionState.disconnecting:
          _connectionState = FloowerConnectionState.disconnecting;
          break;

        case DeviceConnectionState.disconnected:
          _connectionState = FloowerConnectionState.disconnected;
          disconnect();
          break;
      }

      notifyListeners();
    }
    // TODO: hande connection errors?
  }

  Future<void> _pair() async {
    assert(_connectionState == FloowerConnectionState.connected);
    print("Pairing device");

    Duration transitionDuration = const Duration(milliseconds: 500);

    // try to send pairing command to change color and open a bit
    WriteResult result = await writeState(openLevel: 20, color: _pairingColor, duration: transitionDuration);
    if (!result.success) {
      _connectionFailureMessage = result.errorMessage;
      disconnect();
    }
    else {
      // if success close again
      await new Future.delayed(transitionDuration);
      await writeState(openLevel: 0, color: _pairingColor, duration: transitionDuration);

      _connectionState = FloowerConnectionState.pairing;
      notifyListeners();
    }

    print("Paired to device");
  }

  void pair() async {
    if (_connectionState == FloowerConnectionState.pairing) {
      await writeState(openLevel: 0, color: Colors.black, duration: Duration(milliseconds: 500)); // end pairing
      _connectionState = FloowerConnectionState.paired;
      notifyListeners();
    }
  }
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

class FloowerConnectorDemo extends FloowerConnector {

  bool _paired = true;
  int _petalsOpenLevel = 0;
  Color _color = FloowerColor.black.hwColor;
  List<Color> _colorsScheme = List.of(FloowerColor.DEFAULT_SCHEME).map((color) => color.hwColor).toList();
  String _name = "Floower Demo";
  int _touchThreshold = 45;

  @override
  FloowerConnectionState get state => FloowerConnectionState.paired;

  @override
  Future<WriteResult> writeState({
    int openLevel,
    Color color,
    Duration duration = const Duration(seconds: 1), // max 25s
  }) async {
    if (openLevel != null) {
      _petalsOpenLevel = openLevel;
    }
    if (color != null) {
      _color = color;
    }
    notifyListeners();
    return WriteResult(success: true);
  }

  Future<WriteResult> writeName(String name) async {
    _name = name;
    notifyListeners();
    return WriteResult(success: true);
  }

  Future<WriteResult> writeTouchThreshold(int touchThreshold) async {
    _touchThreshold = touchThreshold;
    notifyListeners();
    return WriteResult(success: true);
  }

  Future<WriteResult> writeColorScheme({List<Color> colorScheme}) async {
    _colorsScheme = colorScheme;
    notifyListeners();
    return WriteResult(success: true);
  }

  Future<FloowerState> readState() async {
    return FloowerState(petalsOpenLevel: _petalsOpenLevel, color: _color);
  }

  Future<String> readName() async {
    return _name;
  }

  Future<int> readTouchThreshold() async {
    return _touchThreshold;
  }

  Future<String> readModelName() async {
    return "Demo";
  }

  Future<int> readSerialNumber() async {
    return 0;
  }

  Future<int> readHardwareRevision() async {
    return 7;
  }

  Future<int> readFirmwareVersion() async {
    return 4;
  }

  Future<List<Color>> readColorsScheme() async {
    return _colorsScheme;
  }

  Stream<int> subscribeBatteryLevel() {
    return Stream.value(75);
  }

  Future<void> disconnect() async {
    _paired = false;
    notifyListeners();
  }
}