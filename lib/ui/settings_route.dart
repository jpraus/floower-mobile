import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:meta/meta.dart';
import 'package:provider/provider.dart';
import 'package:system_setting/system_setting.dart';

import 'package:Floower/logic/floower_model.dart';
import 'package:Floower/logic/floower_connector.dart';
import 'package:Floower/ui/device.dart';
import 'package:Floower/ui/cupertino_list.dart';

class SettingsRoute extends StatelessWidget {
  static const ROUTE_NAME = '/settings';

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.extraLightBackgroundGray,
      navigationBar: CupertinoNavigationBar(
        middle: Text('Settings'),
      ),
      child: SafeArea(
        child: _SettingsScreen(),
      ),
    );
  }
}

class _SettingsScreen extends StatelessWidget {
  const _SettingsScreen({
    Key key
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<FloowerModel>(
      builder: (_, floowerModel, __) => ListView(
        children: _buildSettingsContent(floowerModel),
      ),
    );
  }

  List<Widget> _buildSettingsContent(FloowerModel floowerModel) {
    bool deviceConnected = false;
    List<Widget> column = [];

    // connected devices
    column.add(const SizedBox(height: 35));
    column.add(CupertinoList(
      children: [

      ],
    ));
    /*
    column.add(CupertinoList(
      children: [
        ConnectedDeviceListItem(
          device: floowerConnector.device,
          connectionState: floowerConnector.connectionState,
          onDisconnect: _onDeviceDisconnect
        )
      ],
    ));

    // discover devices
    column.add(const SizedBox(height: 35));
    column.add(GestureDetector(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Row(
          children: <Widget>[
            Text(scannerState.scanIsInProgress ? "SCANNING FOR DEVICES" : "DISCOVERED DEVICES", style: FloowerTextTheme.listLabel),
            const SizedBox(width: 10),
            scannerState.scanIsInProgress ? CupertinoActivityIndicator() : Icon(CupertinoIcons.refresh),
          ],
        ),
      ),
      onTap: scannerState.scanIsInProgress ? _stopScanning : _startScanning,
    ));

    // discovered devices
    List<Widget> discoveredDevices = [];
    for (DiscoveredDevice device in scannerState.discoveredDevices) {
      if (floowerConnector.connectionState == FloowerConnectionState.disconnected || device.id != floowerConnector.device.id) {
        discoveredDevices.add(new DiscoveredDeviceListItem(
            device: device,
            onTap: _onDiscoveredDeviceTap
        ));
        // skip connected devices
      }
    }
    column.add(CupertinoList(
        children: discoveredDevices
    ));
    if (!discoveredDevices.isEmpty) {
      column.add(Padding(
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        child: const Text("Tap the device to connected", style: FloowerTextTheme.listLabel),
      ));
    }
*/
    return column;
  }
}