import 'dart:async';

import 'package:flutter/material.dart';
import 'package:Floower/logic/floower_connector.dart';
import 'package:Floower/logic/floower_color.dart';

class FloowerModel extends ChangeNotifier {

  FloowerConnector _floowerConnector;
  bool _paired = false;
  StreamSubscription _stateSubscription;
  StreamSubscription _batteryLevelSubscription;
  StreamSubscription _batteryStateSubscription;

  Debouncer _stateDebouncer = Debouncer(duration: Duration(milliseconds: 200));
  Debouncer _touchThresholdDebouncer = Debouncer(duration: Duration(seconds: 1));
  Debouncer _colorSchemeDebouncer = Debouncer(duration: Duration(seconds: 1));

  // read/write
  int _petalsOpenLevel = 0; // TODO read from state
  FloowerColor _color = FloowerColor.black;
  List<FloowerColor> _colorsScheme; // max 10 colos
  String _name = "";
  int _touchThreshold;

  // read only
  int _serialNumber = 0;
  String _modelName = "";
  int _firmwareVersion = 0;
  int _hardwareRevision = 0;
  int _batteryLevel = -1; // -1 = unknown
  BatteryState _batteryState;

  FloowerColor get color => _color;
  String get name => _name;
  int get touchThreshold => _touchThreshold;
  int get serialNumber => _serialNumber;
  String get modelName => _modelName;
  int get firmwareVersion => _firmwareVersion;
  int get hardwareRevision => _hardwareRevision;
  int get batteryLevel => _batteryLevel;
  bool get batteryCharging => _batteryState?.charging == true;

  bool get connected => _paired;
  bool get connecting => connectionState == FloowerConnectionState.connecting || connectionState == FloowerConnectionState.pairing;
  bool get disconnected => !connected && !connecting;
  FloowerConnectionState get connectionState => _floowerConnector != null ? _floowerConnector.state : FloowerConnectionState.disconnected;
  bool get demo => _floowerConnector?.demo == true;

  void setColor(FloowerColor color) {
    _color = color;
    notifyListeners();

    print("Change color to $color");

    _stateDebouncer.debounce(() {
      _floowerConnector?.writeState(color: color.hwColor, duration: Duration(milliseconds: 1000));
    });
  }

  void playAnimation(int animation) {
    _color = FloowerColor.black;
    notifyListeners();

    print("Play animation $animation");

    _stateDebouncer.debounce(() {
      _floowerConnector?.writeState(animation: animation);
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

  void connect(FloowerConnector floowerConnector) {
    _floowerConnector?.removeListener(_checkFloowerConnectorState);
    _floowerConnector = floowerConnector;
    _floowerConnector.addListener(_checkFloowerConnectorState);
    this._checkFloowerConnectorState();
  }

  void disconnect() async {
    if (_floowerConnector != null) {
      await _stateSubscription?.cancel();
      await _batteryLevelSubscription?.cancel();
      await _batteryStateSubscription?.cancel();
      _floowerConnector.removeListener(_checkFloowerConnectorState);
      await _floowerConnector.disconnect();
      _floowerConnector = null;
      _colorsScheme = null;
      _paired = false;
      notifyListeners();
    }
  }

  void _checkFloowerConnectorState() {
    bool paired = _floowerConnector?.state == FloowerConnectionState.paired;
    if (paired != _paired) {
      _paired = paired;
      if (paired) {
        _onFloowerPaired();
      }
    }
    notifyListeners();
  }

  void _onFloowerPaired() async {
    print("Loading Floower Information");

    FloowerState state = await _floowerConnector.readState();
    if (state != null) {
      _color = FloowerColor.fromHwColor(state.color);
      _petalsOpenLevel = state.petalsOpenLevel;
      notifyListeners();
    }

    _name = await _floowerConnector.readName();
    _touchThreshold = await _floowerConnector.readTouchThreshold();
    _serialNumber = await _floowerConnector.readSerialNumber();
    _modelName = await _floowerConnector.readModelName();
    _firmwareVersion = await _floowerConnector.readFirmwareVersion();
    _hardwareRevision = await _floowerConnector.readHardwareRevision();
    notifyListeners();

    // subscriptions
    await _stateSubscription?.cancel();
    _stateSubscription = _floowerConnector.subscribeState().listen(_onStateChange);
    await _batteryLevelSubscription?.cancel();
    _batteryLevelSubscription = _floowerConnector.subscribeBatteryLevel().listen(_onBatteryLevel);
    await _batteryStateSubscription?.cancel();
    _batteryStateSubscription = _floowerConnector.subscribeBatteryState().listen(_onBatteryState);
  }

  void _onStateChange(FloowerState state) {
    if (_paired) {
      _petalsOpenLevel = state.petalsOpenLevel;
      _color = FloowerColor.fromHwColor(state.color);
      notifyListeners();
    }
  }

  void _onBatteryLevel(int batteryLevel) {
    if (_paired && _batteryLevel != batteryLevel) {
      print("Updating battery level: $batteryLevel%");
      _batteryLevel = batteryLevel;
      notifyListeners();
    }
  }

  void _onBatteryState(BatteryState batteryState) {
    if (_paired && _batteryState != batteryState) {
      print("Updating battery state: $batteryState");
      _batteryState = batteryState;
      notifyListeners();
    }
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