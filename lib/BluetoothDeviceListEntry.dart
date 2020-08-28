import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

class BluetoothDeviceListEntry extends StatelessWidget {

  final DiscoveredDevice device;
  final GestureTapCallback onTap;
  final GestureLongPressCallback onLongPress;
  final bool isLast;
  final bool isFirst;

  const BluetoothDeviceListEntry({
    Key key,
    @required this.device,
    this.onTap,
    this.onLongPress,
    this.isLast = false,
    this.isFirst = false
}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    //Widget w = new Expanded(child: Text(device.name ?? "Unknown device"));
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.only(left: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: isFirst ? const BorderSide(width: 1, color: CupertinoColors.lightBackgroundGray) : BorderSide.none,
            bottom: isLast ? const BorderSide(width: 1, color: CupertinoColors.lightBackgroundGray) : BorderSide.none
          ),
        ),
        child: Container(
          padding: EdgeInsets.only(right: 18, top: 8, bottom: 8),
          decoration: BoxDecoration(
            border: Border(
              bottom: isLast ? BorderSide.none : const BorderSide(width: 1, color: CupertinoColors.lightBackgroundGray)
            )
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Text(_devicename(device))
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  device.rssi != null
                    ? Container(
                      margin: new EdgeInsets.all(8.0),
                      child: Text(device.rssi.toString() + ' dBm', style: _computeTextStyle(device.rssi)),
                    )
                    : Container(width: 0, height: 0),
                  /*device.isConnected
                  ? Icon(Icons.import_export)
                  : Container(width: 0, height: 0),
              device.isBonded
                  ? Icon(Icons.link)
                  : Container(width: 0, height: 0),*/
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static TextStyle _computeTextStyle(int rssi) {
    if (rssi >= -35) {
      return TextStyle(color: Colors.greenAccent[700]);
    }
    else if (rssi >= -45) {
      return TextStyle(color: Color.lerp(Colors.greenAccent[700], Colors.lightGreen, -(rssi + 35) / 10));
    }
    else if (rssi >= -55) {
      return TextStyle(color: Color.lerp(Colors.lightGreen, Colors.lime[600], -(rssi + 45) / 10));
    }
    else if (rssi >= -65) {
      return TextStyle(color: Color.lerp(Colors.lime[600], Colors.amber, -(rssi + 55) / 10));
    }
    else if (rssi >= -75) {
      return TextStyle(color: Color.lerp(Colors.amber, Colors.deepOrangeAccent, -(rssi + 65) / 10));
    }
    else if (rssi >= -85) {
      return TextStyle(color: Color.lerp(Colors.deepOrangeAccent, Colors.redAccent, -(rssi + 75) / 10));
    }
    else {
      return TextStyle(color: Colors.redAccent);
    }
  }

  static String _devicename(DiscoveredDevice device) {
    if (device.name != null && device.name != '') {
      return device.name;
    }
    if (device.id != null && device.id != '') {
      return device.id;
    }
    return "Unknown device";
  }
}
