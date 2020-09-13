import 'dart:async';

import 'package:flutter/material.dart';

import 'package:Floower/logic/floower_connector.dart';

class FloowerModel extends ChangeNotifier {

  final FloowerConnector _floowerConnector;

  Debouncer _colorDebouncer = Debouncer(duration: Duration(milliseconds: 50));
  Color _color = Colors.black;
  bool _connected = false;

  FloowerModel(this._floowerConnector) {
    _floowerConnector.addListener(_onFloowerConnectorChange);
  }

  Color get color {
    return _color;
  }

  void setColor(Color color) {
    _color = color;
    notifyListeners();

    // TODO: throttle
    _colorDebouncer.debounce(() {
      _floowerConnector.sendState(color: color, duration: Duration(milliseconds: 500));
    });
  }

  bool get connected {
    return _connected;
  }

  void setOpen() {

  }

  void _onFloowerConnectorChange() {
    bool connected = _floowerConnector.connectionState == FloowerConnectionState.connected;
    if (connected != _connected) {
      _connected = connected;
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