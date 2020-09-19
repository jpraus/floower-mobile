import 'dart:async';

import 'package:flutter/material.dart';

import 'package:Floower/logic/floower_connector.dart';
import 'package:tinycolor/tinycolor.dart';

class FloowerModel extends ChangeNotifier {

  final FloowerConnector _floowerConnector;
  bool _connected = false;

  Debouncer _sendDebouncer = Debouncer(duration: Duration(milliseconds: 50));

  // read/write
  int _petalsOpenLevel = 0; // TODO read from state
  FloowerColor _color = FloowerColor.black;
  List<FloowerColor> _colorsScheme; // max 10 colos
  String _name;

  // read only
  int _serialNumber;
  String _modelName;
  int _firmwareVersion;
  int _hardwareRevision;
  int _batteryLevel = -1; // -1 = unknown

  FloowerModel(this._floowerConnector) {
    _floowerConnector.addListener(_onFloowerConnectorChange);
  }

  FloowerColor get color => _color;
  String get name => _name;
  int get serialNumber => _serialNumber;
  String get modelName => _modelName;
  int get firmwareVersion => _firmwareVersion;
  int get hardwareRevision => _hardwareRevision;
  int get batteryLevel => _batteryLevel;

  void setColor(FloowerColor color) {
    _color = color;
    notifyListeners();

    print("Change color to $color");

    _sendDebouncer.debounce(() {
      _floowerConnector.writeState(color: color.hwColor, duration: Duration(milliseconds: 100));
    });
  }

  void setName(String name) {
    _name = name;
    notifyListeners();

    print("Change name to $name");

    _floowerConnector.writeName(name);
  }

  void setColorScheme(List<FloowerColor> colorScheme) {
    _colorsScheme = colorScheme;
    notifyListeners();

    _floowerConnector.writeColorScheme(colorScheme: colorScheme);
  }
  
  void mock() {
    _connected = true;
    _colorsScheme = [
      FloowerColor.fromHwRGB(127, 127, 127),
      FloowerColor.fromHwRGB(127, 70, 0),
      FloowerColor.fromHwRGB(127, 30, 0),
      FloowerColor.fromHwRGB(127, 2, 0),
      FloowerColor.fromHwRGB(127, 0, 50),
      FloowerColor.fromHwRGB(127, 0, 127),
      FloowerColor.fromHwRGB(0, 20, 127),
      FloowerColor.fromHwRGB(0, 127, 0),
    ];
    _name = "Floower Mockup";
    _batteryLevel = 75;
    _serialNumber = 0;
    _modelName = "Mockup";
    _firmwareVersion = 0;
    _hardwareRevision = 0;

    notifyListeners();
  }

  bool get connected {
    return _connected;
  }

  void openPetals() {
    _sendDebouncer.debounce(() {
      _floowerConnector.writeState(openLevel: 100, duration: Duration(seconds: 5));
    });
    _petalsOpenLevel = 100;
  }

  void closePetals() {
    _sendDebouncer.debounce(() {
      _floowerConnector.writeState(openLevel: 0, duration: Duration(seconds: 5));
    });
    _petalsOpenLevel = 0;
  }

  bool isOpen() {
    return _petalsOpenLevel == 100;
  }

  Future<List<FloowerColor>> getColorsScheme() async {
    if (_connected) {
      if (_colorsScheme == null) {
        _colorsScheme = (await _floowerConnector.readColorsScheme())
            .map((color) => FloowerColor.fromHwColor(color))
            .toList();
      }
      return _colorsScheme;
    }
    return List.empty();
  }

  void _onFloowerConnectorChange() {
    bool connected = _floowerConnector.connectionState == FloowerConnectionState.connected;
    if (connected != _connected) {
      _connected = connected;
      if (connected) {
        _onFloowerConnected();
      }
      else {
        _onFloowerDisconnected();
      }
      notifyListeners();
    }
  }

  void _onFloowerConnected() {
    // battery level
    // TODO: this is getting read twice .. unsusbcribe somehow
    _floowerConnector.subscribeBatteryLevel().listen((batteryLevel) {
      if (_batteryLevel != batteryLevel) {
        print("Updating battery level: $batteryLevel%");
        _batteryLevel = batteryLevel;
        notifyListeners();
      }
    });

    _loadFloowerInformation();
  }

  void _loadFloowerInformation() async {
    _name = await _floowerConnector.readName();
    _serialNumber = await _floowerConnector.readSerialNumber();
    _modelName = await _floowerConnector.readModelName();
    _firmwareVersion = await _floowerConnector.readFirmwareVersion();
    _hardwareRevision = await _floowerConnector.readHardwareRevision();

    notifyListeners();
  }

  void _onFloowerDisconnected() {
    _color = FloowerColor.black;
    _petalsOpenLevel = 0;
    _colorsScheme = null;
  }
}

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

class FloowerColor {

  final TinyColor _displayColor;

  FloowerColor._(this._displayColor);

  Color get displayColor => _displayColor.color;
  Color get hwColor => _displayColor.brighten(-30).color; // intensity down by 30% so it's nice on the display

  bool isBlack() {
    return _displayColor.getBrightness() == 0;
  }

  bool isLight() {
    return _displayColor.isLight();
  }

  static FloowerColor black = FloowerColor.fromDisplayColor(Colors.black);

  static FloowerColor fromDisplayColor(Color displayColor) {
    return FloowerColor._(TinyColor(displayColor));
  }

  static FloowerColor fromHwColor(Color hwColor) {
    TinyColor color = TinyColor(hwColor);
    return FloowerColor._(color.brighten(30)); // intensity down by 30%
  }

  static FloowerColor fromHwRGB(int red, int green, int blue) {
    return FloowerColor._(TinyColor.fromRGB(r: red, g: green, b: blue, a: 255));
  }

  @override
  String toString() {
    Color color = _displayColor.color;
    return "[${color.red},${color.green},${color.blue}]";
  }

}