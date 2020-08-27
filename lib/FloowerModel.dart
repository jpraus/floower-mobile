import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class FloowerModel extends ChangeNotifier {
  //FlutterBlue flutterBlue = FlutterBlue.instance;

  Color _color;

  Color get color {
    return _color;
  }

  void setColor(Color color) {
    _color = color;
    notifyListeners();
  }
}