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
  String toString() => "(petalsOpenLevel=$petalsOpenLevel color=$color)";
  bool operator ==(o) => o is FloowerState && petalsOpenLevel == o.petalsOpenLevel && color == o.color;
}

class PersonificationSettings {
  int touchThreshold;
  int behavior;
  int speed;
  int maxOpenLevel;
  int lightIntensity;
  PersonificationSettings({this.touchThreshold, this.behavior, this.speed, this.maxOpenLevel, this.lightIntensity});
  String toString() => "(touchThreshold=$touchThreshold behavior=$behavior speed=$speed maxOpenLevel=$maxOpenLevel lightIntensity=$lightIntensity)";
}

enum WriteError {
  generic,
  disconnected,
  unknownCharacteristics,
}

class WriteResult {
  final bool success;
  final WriteError error;
  final String errorMessage;

  WriteResult({
    this.success,
    this.error,
    this.errorMessage
  });
}

enum ReadError {
  generic,
  unknownCharacteristics,
}

class ReadResult {
  final List<int> data;
  final bool success;
  final ReadError error;
  final String errorMessage;

  ReadResult({
    this.data,
    this.success,
    this.error,
    this.errorMessage
  });
}

class BatteryState {
  final bool charging;
  final bool discharging;
  BatteryState({this.charging = false, this.discharging = false});
  String toString() => "(charging=$charging discharging=$discharging)";
  bool operator ==(o) => o is BatteryState && charging == o.charging && discharging == o.discharging;
}

abstract class FloowerConnector extends ChangeNotifier {

  static const int MAX_NAME_LENGTH = 25;
  static const int MAX_SCHEME_COLORS = 10;

  FloowerConnectionState get state;
  bool get demo;

  Future<WriteResult> writeState({
    int openLevel,
    Color color,
    int animation,
    Duration transitionDuration = const Duration(seconds: 1), // max 25s
  });

  Future<WriteResult> writeName(String name);

  Future<WriteResult> writePersonification(PersonificationSettings personificationSettings);

  Future<WriteResult> writeColorScheme({List<Color> colorScheme});

  Stream<FloowerState> subscribeState();

  Future<FloowerState> readState();

  Future<String> readName();

  Future<PersonificationSettings> readPersonification();

  Future<String> readModelName();

  Future<int> readSerialNumber();

  Future<int> readHardwareRevision();

  Future<int> readFirmwareVersion();

  Future<List<Color>> readColorsScheme();

  Stream<int> subscribeBatteryLevel();

  Stream<BatteryState> subscribeBatteryState();

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
  final Uuid FLOOWER_PERSONIFICATION_UUID = Uuid.parse("c380596f-10d2-47a7-95af-95835e0361c7"); // 5 bytes as for now, personification of the Floower (touchThreshold, behavior, speed, maxOpenLevel, lightIntensity)

  final BleProvider _bleProvider;

  FloowerConnectionState _connectionState = FloowerConnectionState.disconnected;
  String _connectionFailureMessage;
  bool _awaitConnectingStart;
  Color _pairingColor;

  String _deviceId;
  StreamSubscription<ConnectionStateUpdate> _deviceConnection;

  FloowerConnectorBle(this._bleProvider);

  FloowerConnectionState get state => _connectionState;
  bool get demo => false;
  String get connectionFailureMessage => _connectionFailureMessage;
  String get deviceId => _deviceId;

  @override
  Future<WriteResult> writeState({
    int openLevel,
    Color color,
    int animation,
    Duration transitionDuration = const Duration(seconds: 1), // max 25s
  }) {
    print("Writing state: petals=$openLevel% color=$color duration=$transitionDuration animation=$animation");

    // compute mode
    int mode = 0;
    mode += color != null ? 1 : 0;
    mode += openLevel != null ? 2 : 0;
    mode += animation != null ? 4 : 0;

    // 6 bytes data packet
    List<int> value = [];
    value.add(openLevel ?? (animation ?? 0));
    value.add(color?.red ?? 0);
    value.add(color?.green ?? 0);
    value.add(color?.blue ?? 0);
    value.add((transitionDuration.inMilliseconds / 100).round());
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
      throw ValueException(message: "Name cannot be empty or longer then ${FloowerConnector.MAX_NAME_LENGTH}");
    }

    return _writeCharacteristic(
        serviceId: FLOOWER_SERVICE_UUID,
        characteristicId: FLOOWER_NAME_UUID,
        value: name.codeUnits
    );
  }

  @override
  Future<WriteResult> writePersonification(PersonificationSettings personificationSettings) {
    if (personificationSettings.touchThreshold < 30 && personificationSettings.touchThreshold > 60) {
      throw ValueException(message: "Invalid touch threshold value [30,60]");
    }
    if (personificationSettings.speed < 5 && personificationSettings.speed > 255) {
      throw ValueException(message: "Invalid speed value [0,255]");
    }
    if (personificationSettings.maxOpenLevel < 10 && personificationSettings.maxOpenLevel > 100) {
      throw ValueException(message: "Invalid speed value [10,100]");
    }
    if (personificationSettings.lightIntensity < 10 && personificationSettings.lightIntensity > 100) {
      throw ValueException(message: "Invalid speed value [10,100]");
    }

    return _writeCharacteristic(
        serviceId: FLOOWER_SERVICE_UUID,
        characteristicId: FLOOWER_PERSONIFICATION_UUID,
        value: [
          personificationSettings.touchThreshold,
          personificationSettings.behavior,
          personificationSettings.speed,
          personificationSettings.maxOpenLevel,
          personificationSettings.lightIntensity
        ]
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
    if (_connectionState != FloowerConnectionState.paired && !(allowPairing && (_connectionState == FloowerConnectionState.connected || _connectionState == FloowerConnectionState.pairing))) {
      return Future.value(WriteResult(
          success: false,
          errorMessage: "Not connected to Floower",
          error: WriteError.disconnected
      ));
    }

    return _bleProvider.ble.writeCharacteristicWithResponse(QualifiedCharacteristic(
        deviceId: _deviceId,
        serviceId: serviceId,
        characteristicId: characteristicId,
    ), value: value).then((value) {
      return WriteResult(
          success: true
      );
    }).catchError((e, stackTrace) {
      WriteError writeError;
      String errorMessage;
      if (e.message is GenericFailure<CharacteristicValueUpdateError> && e.message.code == CharacteristicValueUpdateError.unknown) {
        writeError = WriteError.unknownCharacteristics;
        errorMessage = "Not a Floower.\nPlease choose another device.";
      }
      else if (e.message is GenericFailure<WriteCharacteristicFailure> && e.message.code == WriteCharacteristicFailure.unknown) {
        writeError = WriteError.unknownCharacteristics;
        errorMessage = "Not a Floower.\nPlease choose another device.";
      }
      else if (e.message is GenericFailure) {
        writeError = WriteError.generic;
        errorMessage = e.message.message;
      }
      else {
        writeError = WriteError.generic;
        errorMessage = e.message.toString();
      }
      print("Characteristics write error ${e.toString()}");
      print(stackTrace);
      return WriteResult(
        success: false,
        errorMessage: errorMessage,
        error: writeError
      );
    });
  }

  @override
  Future<FloowerState> readState() {
    return _readCharacteristics(
        serviceId: FLOOWER_SERVICE_UUID,
        characteristicId: FLOOWER_STATE_UUID,
        allowPairing: true
    ).then((value) {
      return _parseState(value);
    }).catchError((e, stackTrace) {
      print("Failed to get state: ${e.toString()}");
      print(stackTrace);
      return null;
    });
  }

  FloowerState _parseState(List<int> value) {
    if (value.length == 0) { // state not initialized yet (bug in firmware)
      return FloowerState(
        petalsOpenLevel: 0,
        color: Colors.black,
      );
    }

    if (value.length != 4) {
      throw ValueException(message: "Invalid format of state value");
    }
    if (value[0] < 0 || value[0] > 100) {
      throw ValueException(message: "Petals open level value out of range");
    }
    if (value[1] < 0 || value[1] > 255 || value[2] < 0 || value[2] > 255 || value[3] < 0 || value[3] > 255) {
      throw ValueException(message: "RGB color values out of range");
    }

    print("Got state $value");
    return FloowerState(
      petalsOpenLevel: value[0],
      color: Color.fromRGBO(value[1], value[2], value[3], 1),
    );
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
    }).catchError((e, stackTrace) {
      print("Failed to get name ${e.toString()}");
      print(stackTrace);
      return "";
    });
  }

  @override
  Future<PersonificationSettings> readPersonification() {
    return _readCharacteristics(
        serviceId: FLOOWER_SERVICE_UUID,
        characteristicId: FLOOWER_PERSONIFICATION_UUID
    ).then((value) {
      PersonificationSettings personification = PersonificationSettings(
        touchThreshold: value[0],
        behavior: value[1] ?? 0,
        speed: value[2] ?? 0,
        maxOpenLevel: value[3] ?? 0,
        lightIntensity: value[4] ?? 0,
      );
      print("Got personification settings '$personification'");
      return personification;
    }).catchError((e, stackTrace) {
      print("Failed to get personification settings: ${e.toString()}");
      print(stackTrace);
      return null;
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
    }).catchError((e, stackTrace) {
      print("Failed to get model name: ${e.toString()}");
      print(stackTrace);
      return "";
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
    }).catchError((e, stackTrace) {
      print("Failed to get serial number: ${e.toString()}");
      print(stackTrace);
      return 0;
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
    }).catchError((e, stackTrace) {
      print("Failed to get hardware revision: ${e.toString()}");
      print(stackTrace);
      return 0;
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
    }).catchError((e, stackTrace) {
      print("Failed to get firmware revision: ${e.toString()}");
      print(stackTrace);
      return 0;
    });
  }

  @override
  Future<List<Color>> readColorsScheme() {
    return _readCharacteristics(
        serviceId: FLOOWER_SERVICE_UUID,
        characteristicId: FLOOWER_COLORS_SCHEME_UUID
    ).then((value) {
      if (value.length % 3 != 0) {
        throw ValueException(message: "Invalid colors scheme format");
      }
      for (int byte in value) {
        if (byte < 0 || byte > 255) {
          throw ValueException(message: "RGB color values out of range");
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
    }).catchError((e, stackTrace) {
      print("Failed to get color scheme: ${e.toString()}");
      print(stackTrace);
      return [];
    });
  }

  Future<List<int>> _readCharacteristics({
    @required Uuid serviceId,
    @required Uuid characteristicId,
    bool allowPairing = false,
    bool retry = true,
    bool disconnectOnError = true
  }) async {
    if (_connectionState != FloowerConnectionState.paired && !(allowPairing && (_connectionState == FloowerConnectionState.connected || _connectionState == FloowerConnectionState.pairing))) {
      throw DisconnectedException(message: "Not connected to Floower");
    }

    print("Getting characteristics $characteristicId");
    return _bleProvider.ble.readCharacteristic(QualifiedCharacteristic(
        deviceId: _deviceId,
        serviceId: serviceId,
        characteristicId: characteristicId
    )).then((value) {
      print("Got characteristics $characteristicId: $value");
      return value;
    }).catchError((e, stackTrace) {
      if (e.message is GenericFailure<CharacteristicValueUpdateError> && e.message.code == CharacteristicValueUpdateError.unknown) {
        throw UnknownCharacteristicsException(message: e.message.toString());
      }
      print("Unhandled characteristic read error ${e.toString()}");
      print(stackTrace);

      if (disconnectOnError) {
        disconnect();
        throw DisconnectedException(message: e.message.toString());
      }
      else {
        throw FailureException(message: e.message.toString());
      }
    });
    // TODO: handle NoBleCharacteristicDataReceived, NoBleDeviceConnectionStateReceived
  }

  @override
  Stream<FloowerState> subscribeState() {
    assert(_connectionState == FloowerConnectionState.paired || _connectionState == FloowerConnectionState.pairing);

    // TODO: handle errors
    return _bleProvider.ble.subscribeToCharacteristic(QualifiedCharacteristic(
      deviceId: _deviceId,
      serviceId: FLOOWER_SERVICE_UUID,
      characteristicId: FLOOWER_STATE_UUID,
    )).map((value) {
      print("Got state notification $value");
      return _parseState(value);
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

  @override
  Stream<BatteryState> subscribeBatteryState() {
    assert(_connectionState == FloowerConnectionState.paired || _connectionState == FloowerConnectionState.pairing);

    // TODO: handle errors
    return _bleProvider.ble.subscribeToCharacteristic(QualifiedCharacteristic(
      deviceId: _deviceId,
      serviceId: BATTERY_UUID,
      characteristicId: BATTERY_POWER_STATE_UUID,
    )).map((bytes) {
      print("Got battery state notification $bytes");
      if (bytes.length == 1) {
        int dischargingState = (bytes[0] >> 2) & 3;
        int chargingState = (bytes[0] >> 4) & 3;
        return BatteryState(
          discharging: dischargingState == 3,
          charging: chargingState == 3
        );
      }
      return BatteryState();
    });
  }

  Future<void> connect(String deviceId, {
    Color pairingColor
  }) async {
    _awaitConnectingStart = _connectionState != FloowerConnectionState.disconnected;
    _connectionState = FloowerConnectionState.connecting;
    _connectionFailureMessage = null;

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
    if (_awaitConnectingStart && (stateUpdate.connectionState == DeviceConnectionState.connecting || stateUpdate.connectionState == DeviceConnectionState.connected)) {
      _awaitConnectingStart = false;
    }
    if (!_awaitConnectingStart) { // prevent updates while waiting for connecting to start
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
    WriteResult result = await writeState(openLevel: 20, color: _pairingColor, transitionDuration: transitionDuration);
    if (!result.success) {
      _connectionFailureMessage = result.errorMessage;
      await disconnect();
    }
    else {
      // if success close again
      await new Future.delayed(transitionDuration);
      await writeState(openLevel: 0, color: _pairingColor, transitionDuration: transitionDuration);

      _connectionState = FloowerConnectionState.pairing;
      notifyListeners();
      print("Pairing device finished");
    }
  }

  void pair() async {
    if (_connectionState == FloowerConnectionState.pairing) {
      await writeState(openLevel: 0, color: Colors.black, transitionDuration: Duration(milliseconds: 500)); // end pairing
      _connectionState = FloowerConnectionState.paired;
      notifyListeners();
    }
  }
}

class FloowerConnectorDemo extends FloowerConnector {

  bool _paired = true;
  int _petalsOpenLevel = 0;
  Color _color = FloowerColor.black.hwColor;
  List<Color> _colorsScheme = List.of(FloowerColor.DEFAULT_SCHEME).map((color) => color.hwColor).toList();
  String _name = "Floower Demo";
  PersonificationSettings _personificationSettings = PersonificationSettings(
    touchThreshold: 45,
    behavior: 0,
    speed: 50,
    maxOpenLevel: 100,
    lightIntensity: 70
  );

  FloowerConnectionState get state => _paired ? FloowerConnectionState.paired : FloowerConnectionState.disconnected;
  bool get demo => true;

  @override
  Future<WriteResult> writeState({
    int openLevel,
    Color color,
    int animation,
    Duration transitionDuration = const Duration(seconds: 1), // max 25s
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

  Future<WriteResult> writePersonification(PersonificationSettings personificationSettings) async {
    _personificationSettings = personificationSettings;
    notifyListeners();
    return WriteResult(success: true);
  }

  Future<WriteResult> writeColorScheme({List<Color> colorScheme}) async {
    _colorsScheme = colorScheme;
    notifyListeners();
    return WriteResult(success: true);
  }

  Stream<FloowerState> subscribeState() {
    return Stream.value(FloowerState(petalsOpenLevel: _petalsOpenLevel, color: _color));
  }

  Future<FloowerState> readState() async {
    return FloowerState(petalsOpenLevel: _petalsOpenLevel, color: _color);
  }

  Future<String> readName() async {
    return _name;
  }

  Future<PersonificationSettings> readPersonification() async {
    return _personificationSettings;
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
    return 7;
  }

  Future<List<Color>> readColorsScheme() async {
    return _colorsScheme;
  }

  Stream<int> subscribeBatteryLevel() {
    return Stream.value(75);
  }

  Stream<BatteryState> subscribeBatteryState() {
    return Stream.value(BatteryState());
  }

  Future<void> disconnect() async {
    _paired = false;
    notifyListeners();
  }
}

class ConnectorException implements Exception {
  final String message;
  ConnectorException({this.message = "Invalid value"});
  String toString() => message;
}

class ValueException extends ConnectorException {
  ValueException({message = "Invalid value"}) : super(message: message);
}

class DisconnectedException extends ConnectorException {
  DisconnectedException({message = "Disconnected from device"}) : super(message: message);
}

class UnknownCharacteristicsException extends ConnectorException {
  UnknownCharacteristicsException({message = "Unknown characteristics"}) : super(message: message);
}

class FailureException extends ConnectorException {
  FailureException({message = "Failed"}) : super(message: message);
}