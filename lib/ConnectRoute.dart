import 'dart:async';

import 'package:Floower/data/FloowerModel.dart';
import 'package:Floower/main.dart';
import 'package:Floower/ui/ConnectedDevice.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:meta/meta.dart';
import 'package:provider/provider.dart';
import 'package:system_setting/system_setting.dart';

import 'ble/ble_scanner.dart';
import 'ui/DeviceListItem.dart';
import 'ui/Commons.dart';

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
        return Container();
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
            CupertinoButton.filled(
              child: Text(buttonText),
              onPressed: onButtonPressed,
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
    Provider.of<FloowerModel>(context, listen: false).connect(device);
  }

  void _onDeviceDisconnect() async {
    Provider.of<FloowerModel>(context, listen: false).disconnect();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FloowerModel>(
      builder: (_, floowerModel, __) => StreamBuilder<BleScannerState>(
        stream: _bleScanner.state,
        initialData: const BleScannerState(
          discoveredDevices: [],
          scanIsInProgress: false,
        ),
        builder: (_, scannerState) => ListView(
          children: _buildScanList(scannerState.data, floowerModel),
        ),
      ),
    );
  }

  List<Widget> _buildScanList(BleScannerState scannerState, FloowerModel floowerModel) {
    ConnectionStateUpdate deviceState = floowerModel.deviceConnectionState;
    List<Widget> list = [];
    int discoveredDevicesCount = scannerState.discoveredDevices.length;

    if (deviceState != null && deviceState.connectionState != DeviceConnectionState.disconnected) {
      list.add(const SizedBox(height: 35));
      list.add(Padding(
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: const Text("CONNECTED DEVICES", style: FloowerTextTheme.listLabel),
      ));
      list.add(ConnectedDevice(
        device: floowerModel.device,
        connectionState: floowerModel.deviceConnectionState,
        onDisconnect: _onDeviceDisconnect
        //onTap: ,
      ));
      discoveredDevicesCount = discoveredDevicesCount - 1;
    }

    list.add(const SizedBox(height: 35));
    list.add(GestureDetector(
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

    int index = 0;
    for (DiscoveredDevice device in scannerState.discoveredDevices) {
      if (deviceState != null && device.id == deviceState.deviceId) {
        continue; // connected device
      }
      list.add(new DeviceListItem(
        device: device,
        onTap: _onDiscoveredDeviceTap,
        isFirst: index == 0,
        isLast: index == discoveredDevicesCount - 1,
      ));
      index++;
    }

    return list;
  }
}