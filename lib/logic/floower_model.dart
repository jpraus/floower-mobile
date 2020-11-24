import 'dart:async';

import 'package:flutter/material.dart';

import 'package:Floower/logic/floower_connector.dart';
import 'package:Floower/logic/floower_color.dart';

class FloowerModel extends ChangeNotifier {

  FloowerConnector _floowerConnector;
  bool _paired = false;

  Debouncer _stateDebouncer = Debouncer(duration: Duration(milliseconds: 200));
  Debouncer _touchThresholdDebouncer = Debouncer(duration: Duration(seconds: 1));
  Debouncer _colorSchemeDebouncer = Debouncer(duration: Duration(seconds: 1));

  // read/write
  int _petalsOpenLevel = 0; // TODO read from state
  FloowerColor _color = FloowerColor.black;
  List<FloowerColor> _colorsScheme; // max 10 colos
  String _name;
  int _touchThreshold;

  // read only
  int _serialNumber;
  String _modelName;
  int _firmwareVersion;
  int _hardwareRevision;
  int _batteryLevel = -1; // -1 = unknown

  FloowerColor get color => _color;
  String get name => _name;
  int get touchThreshold => _touchThreshold;
  int get serialNumber => _serialNumber;
  String get modelName => _modelName;
  int get firmwareVersion => _firmwareVersion;
  int get hardwareRevision => _hardwareRevision;
  int get batteryLevel => _batteryLevel;

  void connect(FloowerConnector floowerConnector) {
    _floowerConnector?.removeListener(_onFloowerConnectorChange);
    _floowerConnector = floowerConnector;
    _floowerConnector?.addListener(_onFloowerConnectorChange);
    this._onFloowerConnectorChange();
  }

  void disconnect() {
    if (_floowerConnector != null) {
      _floowerConnector.disconnect();
      _floowerConnector.removeListener(_onFloowerConnectorChange);
      _floowerConnector = null;
      this._onFloowerConnectorChange();
    }
  }

  void setColor(FloowerColor color) {
    _color = color;
    notifyListeners();

    print("Change color to $color");

    _stateDebouncer.debounce(() {
      _floowerConnector?.writeState(color: color.hwColor, duration: Duration(milliseconds: 100));
    });
  }

  void setName(String name) {
    _name = name;
    notifyListeners();

    print("Change name to $name");

    _floowerConnector?.writeName(name);
  }

  void setColorScheme(List<FloowerColor> colorScheme) {
    _colorsScheme = colorScheme;
    notifyListeners();

    _colorSchemeDebouncer.debounce(() {
      _floowerConnector?.writeColorScheme(colorScheme: colorScheme.map((color) => color.hwColor).toList());
    });
  }

  void setTouchThreshold(int touchThreshold) {
    _touchThreshold = touchThreshold;
    notifyListeners();

    print("Change touch threshold to $touchThreshold");

    _touchThresholdDebouncer.debounce(() {
      _floowerConnector?.writeTouchThreshold(touchThreshold);
    });
  }
  
  void mock() {
    _paired = true;
    _colorsScheme = List.of(FloowerColor.DEFAULT_SCHEME);
    _name = "Floower Demo";
    _touchThreshold = 45;
    _batteryLevel = 75;
    _serialNumber = 0;
    _modelName = "Demo";
    _firmwareVersion = 0;
    _hardwareRevision = 0;

    notifyListeners();
  }

  bool get connected {
    return _paired;
  }

  void openPetals() {
    _stateDebouncer.debounce(() {
      _floowerConnector?.writeState(openLevel: 100, duration: Duration(seconds: 5));
    });
    _petalsOpenLevel = 100;
  }

  void closePetals() {
    _stateDebouncer.debounce(() {
      _floowerConnector?.writeState(openLevel: 0, duration: Duration(seconds: 5));
    });
    _petalsOpenLevel = 0;
  }

  void togglePetals() {
    _stateDebouncer.debounce(() async {
      FloowerState currentState = await _floowerConnector?.readState();
      if (currentState != null) {
        int newOpenLevel = currentState.petalsOpenLevel > 0 ? 0 : 100;
        await _floowerConnector?.writeState(openLevel: newOpenLevel, color: color.hwColor, duration: Duration(seconds: 5));
      }
    });
  }

  Future<List<FloowerColor>> getColorsScheme() async {
    if (_paired) {
      if (_colorsScheme == null) {
        _colorsScheme = (await _floowerConnector?.readColorsScheme())
            .map((color) => FloowerColor.fromHwColor(color))
            .toList();
      }
      return _colorsScheme;
    }
    return List.empty();
  }

  void _onFloowerConnectorChange() {
    bool paired = _floowerConnector?.isPaired() == true;
    if (paired != _paired) {
      _paired = paired;
      if (paired) {
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
    _touchThreshold = await _floowerConnector.readTouchThreshold();
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