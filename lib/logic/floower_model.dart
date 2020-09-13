import 'dart:async';

import 'package:flutter/material.dart';

import 'package:Floower/logic/floower_connector.dart';
import 'package:tinycolor/tinycolor.dart';

class FloowerModel extends ChangeNotifier {

  final FloowerConnector _floowerConnector;

  Debouncer _colorDebouncer = Debouncer(duration: Duration(milliseconds: 50));
  FloowerColor _color = FloowerColor.fromDisplayColor(Colors.black);
  List<FloowerColor> _colorsScheme;

  bool _connected = false;

  int _batteryLevel = -1; // unknown

  FloowerModel(this._floowerConnector) {
    _floowerConnector.addListener(_onFloowerConnectorChange);
  }

  FloowerColor get color => _color;
  int get batteryLevel => _batteryLevel;

  void setColor(FloowerColor color) {
    _color = color;
    notifyListeners();

    print("Change color to $color");

    // TODO: throttle
    _colorDebouncer.debounce(() {
      _floowerConnector.sendState(color: color.hwColor, duration: Duration(milliseconds: 100));
    });
  }

  bool get connected {
    return _connected;
  }

  void setOpen() {

  }

  Future<List<FloowerColor>> getColorsScheme() async {
    // TODO: cache
    if (_connected) {
      if (_colorsScheme == null) {
        _colorsScheme = (await _floowerConnector.readColorsScheme())
            .map((color) => FloowerColor.fromHwColor(color))
            .toList();
      }
      return _colorsScheme;
    }
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
    _floowerConnector.subscribeBatteryLevel().listen((batteryLevel) {
      if (_batteryLevel != batteryLevel) {
        print("Updating battery level: $batteryLevel%");
        _batteryLevel = batteryLevel;
        notifyListeners();
      }
    });
  }

  void _onFloowerDisconnected() {
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

  final TinyColor _hwColor;

  FloowerColor._(this._hwColor);

  Color get displayColor => _hwColor.lighten(50).color;
  Color get hwColor => _hwColor.color;

  bool isBlack() {
    return _hwColor.getBrightness() == 0;
  }

  static FloowerColor fromDisplayColor(Color displayColor) {
    return FloowerColor._(TinyColor(displayColor).darken(50));
  }

  static FloowerColor fromHwColor(Color displayColor) {
    return FloowerColor._(TinyColor(displayColor));
  }

  static FloowerColor fromHwRGB(int red, int green, int blue) {
    return FloowerColor._(TinyColor.fromRGB(r: red, g: green, b: blue));
  }

  @override
  String toString() {
    Color color = _hwColor.color;
    return "[${color.red},${color.green},${color.blue}]";
  }

}