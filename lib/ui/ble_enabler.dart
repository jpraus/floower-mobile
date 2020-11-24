import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:meta/meta.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:system_setting/system_setting.dart';

import 'package:Floower/ble/ble_provider.dart';

class BleEnabler extends StatefulWidget {

  BleEnabler({
    @required this.bleProvider,
    this.readyChild,
    Key key
  }) : super(key: key);

  final BleProvider bleProvider;
  final Widget readyChild;

  @override
  BleEnablerState createState() {
    return BleEnablerState();
  }
}

class BleEnablerState extends State<BleEnabler> {

  bool _askedForPermission = false;

  void _requestLocationPermission() async {
    _askedForPermission = true;
    await Permission.location.request();
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.bleProvider.status) {
      case BleStatus.ready:
        return widget.readyChild;

      case BleStatus.poweredOff:
        // BLE off screen
        return _BluetoothUnavailable(
            icon: Icons.bluetooth_disabled,
          title: 'Bluetooth is OFF',
          message: 'Please turn on Bluetooth in order to discover near-by Floowers and connect with them.',
          buttonText: 'Open Preferences',
          onButtonPressed: () => SystemSetting.goto(SettingTarget.BLUETOOTH)
        );

      case BleStatus.locationServicesDisabled:
        // location service off screen
        return _BluetoothUnavailable(
            icon: Icons.location_disabled,
            title: 'Location Service is OFF',
            message: 'Please turn on Location service in order to discover near-by Floowers and connect with them.',
            buttonText: 'Open Preferences',
            onButtonPressed: () => SystemSetting.goto(SettingTarget.LOCATION)
        );

      case BleStatus.unauthorized:
        if (!_askedForPermission) {
          _requestLocationPermission();
        }
        // unauthorized screen
        return _BluetoothUnavailable(
          icon: Icons.bluetooth_disabled,
          title: 'Bluetooth not allowed',
          message: 'Please allow Floower app to use your location service in order to discover near-by Floowers and connect with them.',
          buttonText: 'Open Preferences',
          onButtonPressed: () => openAppSettings()
        );

      //case BleStatus.unknown:
      //case BleStatus.unsupported:
      default:
        // ble dead screen
        return _BluetoothUnavailable(
            icon: Icons.bluetooth_disabled,
            title: 'Bluetooth not supported',
            message: 'This device seems to not support Bluetooth, there is no way how to connect to your Floower.'
        );
    }
  }
}

class _BluetoothUnavailable extends StatelessWidget {

  _BluetoothUnavailable({
    this.icon,
    this.title,
    this.message,
    this.buttonText,
    this.onButtonPressed,
    Key key
  }) : super(key: key);

  final IconData icon;
  final String title;
  final String message;
  final String buttonText;
  final VoidCallback onButtonPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      padding: EdgeInsets.all(20),
      child: Container(
        constraints: BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, size: 80, color: CupertinoColors.inactiveGray),
            const SizedBox(height: 20),
            Text(title, style: TextStyle(fontSize: 20, color: CupertinoColors.inactiveGray)),
            const SizedBox(height: 20),
            Text(message, style: TextStyle(color: CupertinoColors.inactiveGray), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            Container(
              child: buttonText != null ? CupertinoButton.filled(
                child: Text(buttonText),
                onPressed: onButtonPressed,
              ) : null,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
