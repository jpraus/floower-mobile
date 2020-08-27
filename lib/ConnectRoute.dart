import 'dart:async';

import 'package:flutter/cupertino.dart';
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
    _bleScanner.startScan([]);
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
        navigationBar: CupertinoNavigationBar(
          middle: scannerState.data.scanIsInProgress
              ? Text('Discovering Floowers ' + scannerState.data.discoveredDevices.length.toString())
              : Text('Connect Your Floower'),
          trailing: scannerState.data.scanIsInProgress
              ? GestureDetector(
            child: CupertinoActivityIndicator(),
            onTap: _stopScanning,
          )
              : GestureDetector(
            child: Icon(CupertinoIcons.refresh),
            onTap: _startScanning,
          ),
        ),
        child: CustomScrollView(
          slivers: <Widget>[
            SliverSafeArea(
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  if (index < scannerState.data.discoveredDevices.length) {
                    return new BluetoothDeviceListEntry(
                      device: scannerState.data.discoveredDevices[index],
                      onTap: _onDeviceTap,
                    );
                  }
                  return null;
                }),
              ),
            )
          ],
        ),
        /*child: ListView(
          children: widget.scannerState.discoveredDevices
            .map((device) => new BluetoothDeviceListEntry(device: device))
            .toList(),
        ),*/
      ),
    );
  }
}