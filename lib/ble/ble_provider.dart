import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

class BleProvider extends ChangeNotifier {

  final FlutterReactiveBle _ble;
  StreamSubscription _bleStatusSubscription;
  BleStatus _bleStatus = BleStatus.unknown;

  BleProvider(this._ble) : assert(_ble != null) {
    _bleStatusSubscription = _ble.statusStream.listen((bleStatus) {
      if (bleStatus != _bleStatus) {
        _bleStatus = bleStatus;
        notifyListeners();
      }
    });
  }

  FlutterReactiveBle get ble {
    return _ble;
  }

  BleStatus get status {
    return _bleStatus;
  }

  bool get ready {
    return _bleStatus == BleStatus.ready;
  }
}