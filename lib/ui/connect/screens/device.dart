import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

import 'package:Floower/ui/cupertino_list.dart';

class DiscoveredDeviceListItem extends StatelessWidget {

  final DiscoveredDevice device;
  final void Function(DiscoveredDevice device) onTap;

  const DiscoveredDeviceListItem({
    Key key,
    @required this.device,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CupertinoListItem(
      onTap: () => onTap(device),
      title: Text(DeviceUtils.deviceName(device),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
      trailing: GestureDetector(
        child: Text("CONNECT", style: CupertinoTheme.of(context).textTheme.actionTextStyle),
        onTap: () => onTap(device),
      ),
      //trailing: Icon(CupertinoIcons.forward, color: CupertinoColors.tertiaryLabel),
    );
  }

  static TextStyle _computeTextStyle(int rssi) {
    if (rssi >= -35) {
      return TextStyle(color: Colors.greenAccent[700]);
    }
    else if (rssi >= -45) {
      return TextStyle(color: Color.lerp(
          Colors.greenAccent[700], Colors.lightGreen, -(rssi + 35) / 10));
    }
    else if (rssi >= -55) {
      return TextStyle(color: Color.lerp(
          Colors.lightGreen, Colors.lime[600], -(rssi + 45) / 10));
    }
    else if (rssi >= -65) {
      return TextStyle(
          color: Color.lerp(Colors.lime[600], Colors.amber, -(rssi + 55) / 10));
    }
    else if (rssi >= -75) {
      return TextStyle(color: Color.lerp(
          Colors.amber, Colors.deepOrangeAccent, -(rssi + 65) / 10));
    }
    else if (rssi >= -85) {
      return TextStyle(color: Color.lerp(
          Colors.deepOrangeAccent, Colors.redAccent, -(rssi + 75) / 10));
    }
    else {
      return TextStyle(color: Colors.redAccent);
    }
  }
}

class DeviceUtils {
  static String deviceName(DiscoveredDevice device) {
    if (device.name != null && device.name != '') {
      return device.name;
    }
    if (device.id != null && device.id != '') {
      return device.id;
    }
    return "Unknown device";
  }
}
