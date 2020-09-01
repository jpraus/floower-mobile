import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

class ConnectedDevice extends StatelessWidget {

  final DiscoveredDevice device;
  final ConnectionStateUpdate connectionState;
  final void Function() onDisconnect;

  const ConnectedDevice({
    Key key,
    @required this.device,
    @required this.connectionState,
    this.onDisconnect
}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    //Widget w = new Expanded(child: Text(device.name ?? "Unknown device"));
    return GestureDetector(
      //onTap: () => onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(width: 1, color: CupertinoColors.lightBackgroundGray),
            bottom: BorderSide(width: 1, color: CupertinoColors.lightBackgroundGray)
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Text(_deviceName(device))
              ),
            ),
            _deviceStateAction(context)
          ],
        ),
      ),
    );
  }

  Widget _deviceStateAction(BuildContext context) {
    switch (connectionState.connectionState) {
      case DeviceConnectionState.connected:
        return GestureDetector(
          child: Text("DISCONNECT", style: CupertinoTheme.of(context).textTheme.actionTextStyle),
          onTap: onDisconnect,
        );

      case DeviceConnectionState.connecting:
        return Row(
          children: [
            Text("Connecting"),
            SizedBox(width: 10),
            CupertinoActivityIndicator()
          ],
        );

      case DeviceConnectionState.disconnecting:
        return Text("Disconnecting");
    }
    return Container();
  }

  static String _deviceName(DiscoveredDevice device) {
    if (device.name != null && device.name != '') {
      return device.name;
    }
    if (device.id != null && device.id != '') {
      return device.id;
    }
    return "Unknown device";
  }
}
