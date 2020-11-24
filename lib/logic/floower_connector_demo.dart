import 'dart:async';

import 'package:Floower/logic/floower_connector.dart';
import 'package:Floower/logic/floower_color.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class FloowerConnectorDemo extends FloowerConnector {

  bool _paired = true;
  int _petalsOpenLevel = 0;
  Color _color = FloowerColor.black.hwColor;
  List<Color> _colorsScheme = List.of(FloowerColor.DEFAULT_SCHEME).map((color) => color.hwColor).toList();
  String _name = "Floower Demo";
  int _touchThreshold = 45;

  @override
  bool isPaired() {
    return _paired;
  }

  @override
  Future<WriteResult> writeState({
    int openLevel,
    Color color,
    Duration duration = const Duration(seconds: 1), // max 25s
  }) async {
    if (openLevel != null) {
      _petalsOpenLevel = openLevel;
    }
    if (color != null) {
      _color = color;
    }
    notifyListeners();
    return WriteResult(success: true);
  }

  Future<WriteResult> writeName(String name) async {
    _name = name;
    notifyListeners();
    return WriteResult(success: true);
  }

  Future<WriteResult> writeTouchThreshold(int touchThreshold) async {
    _touchThreshold = touchThreshold;
    notifyListeners();
    return WriteResult(success: true);
  }

  Future<WriteResult> writeColorScheme({List<Color> colorScheme}) async {
    _colorsScheme = colorScheme;
    notifyListeners();
    return WriteResult(success: true);
  }

  Future<FloowerState> readState() async {
    return FloowerState(petalsOpenLevel: _petalsOpenLevel, color: _color);
  }

  Future<String> readName() async {
    return _name;
  }

  Future<int> readTouchThreshold() async {
    return _touchThreshold;
  }

  Future<String> readModelName() async {
    return "Demo";
  }

  Future<int> readSerialNumber() async {
    return 0;
  }

  Future<int> readHardwareRevision() async {
    return 7;
  }

  Future<int> readFirmwareVersion() async {
    return 4;
  }

  Future<List<Color>> readColorsScheme() async {
    return _colorsScheme;
  }

  Stream<int> subscribeBatteryLevel() {
    return Stream.value(75);
  }

  Future<void> disconnect() async {
    _paired = false;
    notifyListeners();
  }
}