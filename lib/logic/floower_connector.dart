import 'dart:async';
import 'package:flutter/material.dart';

class FloowerState {
  final int petalsOpenLevel;
  final Color color;

  FloowerState({this.petalsOpenLevel, this.color});
}

class WriteResult {
  final bool success;
  final String errorMessage;

  WriteResult({
    this.success = true,
    this.errorMessage
  });
}

abstract class FloowerConnector extends ChangeNotifier {

  static const int MAX_NAME_LENGTH = 25;
  static const int MAX_SCHEME_COLORS = 10;

  bool isPaired();

  Future<WriteResult> writeState({
    int openLevel,
    Color color,
    Duration duration = const Duration(seconds: 1), // max 25s
  });

  Future<WriteResult> writeName(String name);

  Future<WriteResult> writeTouchThreshold(int touchThreshold);

  Future<WriteResult> writeColorScheme({List<Color> colorScheme});

  Future<FloowerState> readState();

  Future<String> readName();

  Future<int> readTouchThreshold();

  Future<String> readModelName();

  Future<int> readSerialNumber();

  Future<int> readHardwareRevision();

  Future<int> readFirmwareVersion();

  Future<List<Color>> readColorsScheme();

  Stream<int> subscribeBatteryLevel();

  Future<void> disconnect();

}