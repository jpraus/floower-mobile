import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PersistentStorage extends ChangeNotifier {

  String _pairedDeviceId;

  PersistentStorage() {
    _load();
  }

  Future<void> _load() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _pairedDeviceId = prefs.getString("pairedDevice");
    notifyListeners();
  }

  String get pairedDevice {
    if (_pairedDeviceId != null) {
      print('Got previously paired device $_pairedDeviceId');
    }
    return _pairedDeviceId;
  }

  void set pairedDevice(String deviceId) {
    print("New paired device $deviceId");
    _pairedDeviceId = deviceId;
    SharedPreferences.getInstance().then((prefs) => prefs.setString("pairedDevice", deviceId));
    notifyListeners();
  }

  void removePairedDevice() async {
    _pairedDeviceId = null;
    SharedPreferences.getInstance().then((prefs) => prefs.remove("pairedDevice"));
    notifyListeners();
  }

}