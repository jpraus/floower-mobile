import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:meta/meta.dart';
import 'package:provider/provider.dart';

import 'ble/ble_scanner.dart';
import 'BluetoothDeviceListEntry.dart';

class ConnectRoute extends StatelessWidget {
  static const ROUTE_NAME = '/connect';

  @override
  Widget build(BuildContext context) {
    return Consumer<FlutterReactiveBle>(
      builder: (_, ble, __) => _DiscoverScreen(
        ble: ble
      )
    );
  }
}

class _DiscoverScreen extends StatefulWidget {
  const _DiscoverScreen({@required this.ble})
      : assert(ble != null);

  final FlutterReactiveBle ble;
  //final BleScannerState scannerState;
  //final BleScanner Function(List<Uuid>) startScan;
  //final VoidCallback stopScan;

  @override
  _DiscoverScreenState createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<_DiscoverScreen> {

  BleScanner _bleScanner;

  @override
  void initState() {
    _bleScanner = BleScanner(widget.ble);
    super.initState();
  }

  @override
  void dispose() {
    _bleScanner.stopScan();
    _bleScanner.dispose();
    super.dispose();
  }

  void _startScanning() {
    _bleScanner.startScan(timeout: Duration(seconds: 30));
  }

  void _stopScanning() {
    _bleScanner.stopScan();
  }

  void _onDeviceTap() {

  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<BleScannerState>(
      stream: _bleScanner.state,
      initialData: const BleScannerState(
        discoveredDevices: [],
        scanIsInProgress: false,
      ),
      builder: (context, scannerState) => CupertinoPageScaffold(
        // always has data due to initialData
        backgroundColor: CupertinoColors.extraLightBackgroundGray,
        navigationBar: CupertinoNavigationBar(
          middle: Text('Connect Your Floower'),
        ),
        child: SafeArea(
          child: ListView(
            children: _buildList(scannerState.data),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildList(BleScannerState scannerState) {
    List<Widget> list = [];

    list.add(SizedBox(height: 30));
    list.add(GestureDetector(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Row(
          children: <Widget>[
            Text(scannerState.scanIsInProgress ? "SCANNING FOR DEVICES" : "DISCOVERED DEVICES", style: TextStyle(
              fontSize: 14,
              color: CupertinoColors.secondaryLabel)),
            SizedBox(width: 10),
            scannerState.scanIsInProgress ? CupertinoActivityIndicator() : Icon(CupertinoIcons.refresh),
          ],
        ),
      ),
      onTap: scannerState.scanIsInProgress ? _stopScanning : _startScanning,
    ));

    for (int index = 0; index < scannerState.discoveredDevices.length; index++) {
      list.add(new BluetoothDeviceListEntry(
        device: scannerState.discoveredDevices[index],
        onTap: _onDeviceTap,
        isFirst: index == 0,
        isLast: index == scannerState.discoveredDevices.length - 1,
      ));
    }
    return list;
  }
}