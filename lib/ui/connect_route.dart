import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:meta/meta.dart';
import 'package:provider/provider.dart';
import 'package:system_setting/system_setting.dart';

import 'commons.dart';
import 'package:Floower/ble/ble_scanner.dart';
import 'package:Floower/logic/floower_connector.dart';
import 'package:Floower/ui/device.dart';
import 'package:Floower/ui/cupertino_list.dart';

class ConnectRoute extends StatelessWidget {
  static const ROUTE_NAME = '/connect';

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.extraLightBackgroundGray,
      navigationBar: CupertinoNavigationBar(
        middle: Text('Connect Your Floower'),
      ),
      child: SafeArea(
        child: Consumer<FlutterReactiveBle>(
          builder: (context, ble, __) => _DiscoverScreen(
            ble: ble
          )
        ),
      ),
    );
  }
}

class _DiscoverScreen extends StatefulWidget {
  const _DiscoverScreen({
    @required this.ble,
    Key key
  }) : assert(ble != null),
        super(key: key);

  final FlutterReactiveBle ble;

  @override
  _DiscoverScreenState createState() {
    return _DiscoverScreenState();
  }
}

class _DiscoverScreenState extends State<_DiscoverScreen> {

  StreamSubscription _bleStatusSubscription;
  BleStatus _bleStatus = BleStatus.unknown;

  bool askedForPermission = false;
  bool initialScanning = true;

  @override
  void initState() {
    _bleStatusSubscription = widget.ble.statusStream.listen((bleStatus) {
      if (bleStatus != _bleStatus) {
        setState(() => _bleStatus = bleStatus);
      }
    });

    super.initState();
  }

  @override
  void dispose() {
    _bleStatusSubscription?.cancel();
    super.dispose();
  }

  void _requestLocationPermission() async {
    askedForPermission = true;
    await Permission.location.request();
  }

  void _onDeviceTap() {

  }

  @override
  Widget build(BuildContext context) {
    switch (_bleStatus) {
      case BleStatus.ready:
        // scan screen
        return _ScanScreen(ble: widget.ble);

      case BleStatus.poweredOff:
      case BleStatus.locationServicesDisabled:
        // BLE off screen
        return _buildBluetoothUnavailableScreen(
          title: 'Bluetooth is OFF',
          message: 'Please turn on Bluetooth in order to discover near-by Floowers and connect with them.',
          buttonText: 'Turn it ON',
          onButtonPressed: () => SystemSetting.goto(SettingTarget.BLUETOOTH)
        );

      case BleStatus.unauthorized:
        if (!askedForPermission) {
          _requestLocationPermission();
        }
        // unauthorized screen
        return _buildBluetoothUnavailableScreen(
          title: 'Bluetooth not allowed',
          message: 'Please allow Floower app to use your location service in order to discover near-by Floowers and connect with them.',
          buttonText: 'Open Preferences',
          onButtonPressed: () => openAppSettings()
        );

      case BleStatus.unknown:
      case BleStatus.unsupported:
        // ble dead screen
        return _buildBluetoothUnavailableScreen(
            title: 'Bluetooth not supported',
            message: 'This device seems to not support Bluetooth, there is no way how to connect to your Floower.'
        );
    }
  }

  Widget _buildBluetoothUnavailableScreen({String title, String message, String buttonText, VoidCallback onButtonPressed}) {
    return Container(
      alignment: Alignment.center,
      padding: EdgeInsets.all(20),
      child: Container(
        constraints: BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(Icons.bluetooth_disabled, size: 80, color: CupertinoColors.inactiveGray),
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

class _ScanScreen extends StatefulWidget {
  const _ScanScreen({
    @required this.ble,
    Key key
  }) : assert(ble != null),
        super(key: key);

  final FlutterReactiveBle ble;

  @override
  _ScanScreenState createState() {
    return _ScanScreenState();
  }
}

class _ScanScreenState extends State<_ScanScreen> {

  BleScanner _bleScanner;

  @override
  void initState() {
    _bleScanner = BleScanner(widget.ble);
    _startScanning();
    super.initState();
  }

  @override
  void dispose() {
    _bleScanner.dispose();
    super.dispose();
  }

  void _startScanning() {
    _bleScanner.startScan(
      serviceIds: [],
      timeout: Duration(seconds: 30)
    );
  }

  void _stopScanning() {
    _bleScanner.stopScan();
  }

  void _onDiscoveredDeviceTap(DiscoveredDevice device) async {
    _stopScanning();
    Provider.of<FloowerConnector>(context, listen: false).connect(device);
  }

  void _onDeviceDisconnect() async {
    Provider.of<FloowerConnector>(context, listen: false).disconnect();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FloowerConnector>(
      builder: (_, floowerModel, __) => StreamBuilder<BleScannerState>(
        stream: _bleScanner.state,
        initialData: const BleScannerState(
          discoveredDevices: [],
          scanIsInProgress: false,
        ),
        builder: (_, scannerState) => ListView(
          children: _buildScanContent(scannerState.data, floowerModel),
        ),
      ),
    );
  }

  List<Widget> _buildScanContent(BleScannerState scannerState, FloowerConnector floowerConnector) {
    bool deviceConnected = false;
    List<Widget> column = [];

    // connected devices
    if (floowerConnector.connectionState != FloowerConnectionState.disconnected) {
      column.add(const SizedBox(height: 35));
      column.add(Padding(
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: const Text("CONNECTED DEVICES", style: FloowerTextTheme.listLabel),
      ));
      column.add(CupertinoList(
        children: [
          ConnectedDeviceListItem(
            device: floowerConnector.device,
            connectionState: floowerConnector.connectionState,
            onDisconnect: _onDeviceDisconnect
          )
        ],
      ));
      deviceConnected = true;
    }

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

    return column;
  }
}