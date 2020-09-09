import 'dart:async';

import 'package:flutter/material.dart';

import 'floower_connector.dart';

class FloowerModel extends ChangeNotifier {

  final FloowerConnector _floowerConnector;

  Debouncer _colorDebouncer = Debouncer(duration: Duration(milliseconds: 300));
  Color _color;

  FloowerModel(this._floowerConnector);

  Color get color {
    return _color;
  }

  void setColor(Color color) {
    _color = color;
    notifyListeners();

    // TODO: throttle
    _colorDebouncer.debounce(() {
      _floowerConnector.sendColor(color);
    });
  }

  void setOpen() {

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