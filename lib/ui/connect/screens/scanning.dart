import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:meta/meta.dart';

import 'package:Floower/ui/commons.dart';
import 'device.dart';
import 'package:Floower/ui/cupertino_list.dart';
import 'connect_layout.dart';

class BleScanning extends StatelessWidget {

  BleScanning({
    @required this.onCancel,
    Key key
  }) : super(key: key);

  final void Function() onCancel;

  @override
  Widget build(BuildContext context) {
    return ConnectLayout(
      title: "Searching ...",
      image: Image(
          fit: BoxFit.fitHeight,
          image: AssetImage("assets/images/floower-blossom.png")
      ),
      trailing: CupertinoButton.filled(
          child: Text("Cancel"),
          onPressed: onCancel
      ),
      backgroundBuilder: (centerOffset, imageSize) {
        return CircleAnimation(
            duration: Duration(milliseconds: 500),
            startRadius: (imageSize / 2) - 50,
            endRadius: imageSize / 2,
            startOpacity: 0,
            endOpacity: 0.5,
            repeat: true,
            boomerang: true,
            color: Colors.blue,
            centerOffset: centerOffset
        );
      },
    );
  }
}

class BleScanList extends StatelessWidget {

  BleScanList({
    @required this.discoveredDevices,
    @required this.scanIsInProgress,
    @required this.onScanStart,
    @required this.onScanStop,
    @required this.onDeviceConnect,
    Key key
  }) : super(key: key);

  final List<DiscoveredDevice> discoveredDevices;
  final bool scanIsInProgress;
  final void Function() onScanStart;
  final void Function() onScanStop;
  final void Function(DiscoveredDevice device) onDeviceConnect;

  @override
  Widget build(BuildContext context) {
    List<Widget> column = [];

    // discovered devices
    List<Widget> devices = [];
    for (DiscoveredDevice device in discoveredDevices) {
      devices.add(new DiscoveredDeviceListItem(
          device: device,
          onTap: onDeviceConnect
      ));
    }

    column.add(CupertinoList(
        margin: EdgeInsets.only(top: 18),
        heading: GestureDetector(
          child: Row(
            children: <Widget>[
              Text(scanIsInProgress
                  ? "SCANNING FOR DEVICES"
                  : "DISCOVERED DEVICES"),
              const SizedBox(width: 10),
              scanIsInProgress
                  ? CupertinoActivityIndicator()
                  : Icon(CupertinoIcons.refresh),
            ],
          ),
          onTap:
          scanIsInProgress
              ? onScanStop
              : onScanStart,
        ),
        //hint: discoveredDevices.isNotEmpty ? const Text("Tap the device to connect", style: FloowerTextTheme.listLabel) : null,
        children: devices
    ));

    return ListView(
      children: column,
    );
  }
}