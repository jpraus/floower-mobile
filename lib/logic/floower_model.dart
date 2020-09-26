import 'dart:async';

import 'package:flutter/material.dart';

import 'package:Floower/logic/floower_connector.dart';
import 'package:tinycolor/tinycolor.dart';

class FloowerModel extends ChangeNotifier {

  final FloowerConnector _floowerConnector;
  bool _connected = false;

  Debouncer _stateDebouncer = Debouncer(duration: Duration(milliseconds: 200));
  Debouncer _touchTresholdDebouncer = Debouncer(duration: Duration(seconds: 1));
  Debouncer _colorSchemeDebouncer = Debouncer(duration: Duration(seconds: 1));

  // read/write
  int _petalsOpenLevel = 0; // TODO read from state
  FloowerColor _color = FloowerColor.black;
  List<FloowerColor> _colorsScheme; // max 10 colos
  String _name;
  int _touchTreshold;

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
  int get touchTreshold => _touchTreshold;
  int get serialNumber => _serialNumber;
  String get modelName => _modelName;
  int get firmwareVersion => _firmwareVersion;
  int get hardwareRevision => _hardwareRevision;
  int get batteryLevel => _batteryLevel;

  void setColor(FloowerColor color) {
    _color = color;
    notifyListeners();

    print("Change color to $color");

    _stateDebouncer.debounce(() {
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

    _colorSchemeDebouncer.debounce(() {
      _floowerConnector.writeColorScheme(colorScheme: colorScheme);
    });
  }

  void setTouchTreshold(int touchTreshold) {
    _touchTreshold = touchTreshold;
    notifyListeners();

    print("Change touch treshold to $touchTreshold");

    _touchTresholdDebouncer.debounce(() {
      _floowerConnector.writeTouchTreshold(touchTreshold);
    });
  }
  
  void mock() {
    _connected = true;
    _colorsScheme = List.of(FloowerConnector.DEFAULT_SCHEME);
    _name = "Floower Mockup";
    _touchTreshold = 45;
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
    _stateDebouncer.debounce(() {
      _floowerConnector.writeState(openLevel: 100, duration: Duration(seconds: 5));
    });
    _petalsOpenLevel = 100;
  }

  void closePetals() {
    _stateDebouncer.debounce(() {
      _floowerConnector.writeState(openLevel: 0, duration: Duration(seconds: 5));
    });
    _petalsOpenLevel = 0;
  }

  bool togglePetals() {
    _stateDebouncer.debounce(() async {
      FloowerState currentState = await _floowerConnector.readState();
      if (currentState != null) {
        int newOpenLevel = currentState.petalsOpenLevel > 0 ? 0 : 100;
        await _floowerConnector.writeState(openLevel: newOpenLevel, duration: Duration(seconds: 5));
      }
    });
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
    _touchTreshold = await _floowerConnector.readTouchTreshold();
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

  static const int INTENSITY_SHIFT = 30;

  final TinyColor _displayColor;

  FloowerColor._(this._displayColor);

  Color get displayColor => _displayColor.color;
  HSVColor get displayHSVColor => _displayColor.toHsv();
  Color get hwColor => _displayColor.brighten(-INTENSITY_SHIFT).color; // intensity down by 30% so it's nice on the display

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
    return FloowerColor._(color.brighten(INTENSITY_SHIFT)); // display intensity up by 30%
  }

  static FloowerColor fromHwRGB(int red, int green, int blue) {
    return FloowerColor._(TinyColor.fromRGB(r: red, g: green, b: blue, a: 255).brighten(INTENSITY_SHIFT)); // display intensity up by 30%
  }

  @override
  String toString() {
    Color color = _displayColor.color;
    return "[${color.red},${color.green},${color.blue}]";
  }

}