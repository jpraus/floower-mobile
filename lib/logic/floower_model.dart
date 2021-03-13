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

  Throttler _stateTrottler = Throttler(timeout: Duration(milliseconds: 500));
  Debouncer _personificationDebouncer = Debouncer(duration: Duration(seconds: 1));
  Debouncer _colorSchemeDebouncer = Debouncer(duration: Duration(seconds: 1));

  // read/write
  int _petalsOpenLevel = 0; // TODO read from state
  FloowerColor _color = FloowerColor.COLOR_BLACK;
  List<FloowerColor> _colorsScheme; // max 10 colos
  String _name = "";
  PersonificationSettings _personification;

  // read only
  int _serialNumber = 0;
  String _modelName = "";
  int _firmwareVersion = 0;
  int _hardwareRevision = 0;
  int _batteryLevel = -1; // -1 = unknown
  BatteryState _batteryState;

  FloowerColor get color => _color;
  String get name => _name;
  int get touchThreshold => _personification?.touchThreshold;
  int get behavior => _personification?.behavior;
  int get speed => _personification?.speed;
  int get maxOpenLevel => _personification?.maxOpenLevel;
  int get colorBrightness => _personification?.colorBrightness;
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

  void setColor(FloowerColor color, {
      Duration transitionDuration = const Duration(milliseconds: 1000),
      notifyListener = true
  }) {
    _color = color;
    if (notifyListener) {
      notifyListeners();
    }

    print("Change color to $color");

    _stateTrottler.throttle(() {
      _floowerConnector?.writeState(color: color.toColor(), transitionDuration: transitionDuration);
    });
  }

  void playAnimation(int animation) {
    _color = FloowerColor.COLOR_BLACK;
    notifyListeners();

    print("Play animation $animation");

    _stateTrottler.throttle(() {
      _floowerConnector?.writeState(animation: animation);
    });
  }

  void setName(String name) {
    _name = name;
    notifyListeners();

    print("Change name to $name");

    _floowerConnector?.writeName(name);
  }

  void setColorScheme(List<FloowerColor> colorsScheme) {
    _colorsScheme = colorsScheme;
    notifyListeners();

    _colorSchemeDebouncer.debounce(() async {
      WriteResult writeResult = await _floowerConnector?.writeHSColorScheme(colorScheme: colorsScheme.map((color) => color.color).toList());
      if (!writeResult.success) {
        // fallback to RGB color scheme
        _floowerConnector?.writeRGBColorScheme(colorScheme: colorsScheme.map((color) => color.toColor()).toList());
      }
    });
  }

  void setTouchThreshold(int touchThreshold) {
    if (_personification != null) {
      _personification.touchThreshold = touchThreshold;
      notifyListeners();
      print("Change touch threshold to $touchThreshold");

      _personificationDebouncer.debounce(() {
        _floowerConnector?.writePersonification(_personification);
      });
    }
  }

  void setSpeed(int speed) {
    if (_personification != null) {
      _personification.speed = speed;
      notifyListeners();
      print("Change speed to $speed");

      _personificationDebouncer.debounce(() {
        _floowerConnector?.writePersonification(_personification);
      });
    }
  }

  void setMaxOpenLevel(int maxOpenLevel) {
    if (_personification != null) {
      _personification.maxOpenLevel = maxOpenLevel;
      notifyListeners();
      print("Change max open level to $maxOpenLevel%");

      _personificationDebouncer.debounce(() {
        _floowerConnector?.writePersonification(_personification);
      });
    }
  }

  void setColorBrightness(int colorBrightness) {
    if (_personification != null) {
      _personification.colorBrightness = colorBrightness;
      notifyListeners();
      print("Change color brightness to $colorBrightness%");

      _personificationDebouncer.debounce(() async {
        WriteResult writeResult = await _floowerConnector?.writePersonification(_personification);
        if (writeResult.success) {
          FloowerColor color = _color.isBlack() ? FloowerColor.COLOR_WHITE : _color;
          setColor(color);
        }
      });
    }
  }

  void openPetals({ int level, Duration duration }) {
    level = level ?? _personification.maxOpenLevel;
    if (duration == null) {
      int levelDiff = (_petalsOpenLevel - level).abs();
      duration = Duration(milliseconds: (_personification.speed * levelDiff).toInt());
    }
    _stateTrottler.throttle(() {
      _floowerConnector?.writeState(openLevel: level, transitionDuration: duration);
    });
    _petalsOpenLevel = level;
  }

  void closePetals({ duration = const Duration(seconds: 5) }) {
    _stateTrottler.throttle(() {
      _floowerConnector?.writeState(openLevel: 0, transitionDuration: duration);
    });
    _petalsOpenLevel = 0;
  }

  void togglePetals() {
    _stateTrottler.throttle(() async {
      FloowerState currentState = await _floowerConnector?.readState();
      if (currentState != null) {
        int newOpenLevel = currentState.petalsOpenLevel > 0 ? 0 : _personification.maxOpenLevel;
        await _floowerConnector?.writeState(openLevel: newOpenLevel, color: color.toColor(), transitionDuration: Duration(milliseconds: _personification.speed * 100));
      }
    });
  }

  Future<List<FloowerColor>> getColorsScheme() async {
    if (_paired) {
      if (_colorsScheme == null) {
        List<HSVColor> hsvColors = await _floowerConnector.readHSColorScheme();
        if (hsvColors.isNotEmpty) {
          _colorsScheme = hsvColors.map((color) => FloowerColor(color)).toList();
        }
        else {
          // fallback to RGB color scheme
          _colorsScheme = (await _floowerConnector?.readRGBColorScheme())
              .map((color) => FloowerColor.fromColor(color))
              .toList();
        }
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
    _colorsScheme = null; // force loading of the color scheme (lazy)

    FloowerState state = await _floowerConnector.readState();
    if (state != null) {
      _color = FloowerColor.fromColor(state.color);
      _petalsOpenLevel = state.petalsOpenLevel;
      notifyListeners();
    }

    _name = await _floowerConnector.readName();
    _personification = await _floowerConnector.readPersonification();
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
      _color = FloowerColor.fromColor(state.color);
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
  Timer _timer;

  Debouncer({ this.duration });

  debounce(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(duration, action);
  }
}

class Throttler {

  final Duration timeout;
  VoidCallback _action;
  Timer _timer;

  Throttler({ this.timeout });

  throttle(VoidCallback action) {
    _action = action;
    if (_timer == null || !_timer.isActive) {
      _timer = Timer(timeout, () {
        _action.call();
      });
    }
  }
}