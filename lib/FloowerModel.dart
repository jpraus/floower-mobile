import 'package:flutter/cupertino.dart';

class FloowerModel extends ChangeNotifier {
  //FlutterBlue flutterBlue = FlutterBlue.instance;

  Color color;

  void setColor(Color color) {
    this.color = color;
    notifyListeners();
  }

  Color getColor() {
    return this.color;
  }
}