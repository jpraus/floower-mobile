import 'dart:async';

import 'package:Floower/logic/floower_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:meta/meta.dart';
import 'package:provider/provider.dart';

import 'package:Floower/ble/ble_provider.dart';
import 'package:Floower/logic/floower_scanner.dart';
import 'package:Floower/logic/floower_connector.dart';
import 'package:Floower/logic/floower_color.dart';
import 'package:Floower/logic/persistent_storage.dart';
import 'package:Floower/ui/home_route.dart';
import 'package:Floower/ui/ble_enabler.dart';
import 'package:Floower/ui/connect/screens/instructions.dart';
import 'package:Floower/ui/connect/screens/scanning.dart';
import 'package:Floower/ui/connect/screens/connecting.dart';

class ConnectRoute extends StatelessWidget {
  static const ROUTE_NAME = '/connect';

  @override
  Widget build(BuildContext context) {
    BleProvider bleProvider = Provider.of<BleProvider>(context);
    FloowerConnectorBle floowerConnector = Provider.of<FloowerConnectorBle>(context);

    return CupertinoPageScaffold(
      //backgroundColor: CupertinoTheme.of(context).barBackgroundColor,
      navigationBar: CupertinoNavigationBar(
        middle: Text('Connect Your Floower'),
      ),
      child: SafeArea(
        child: BleEnabler(
          bleProvider: bleProvider,
          readyChild: new _ConnectMainScreen(
            bleProvider: bleProvider,
            floowerConnector: floowerConnector
          ),
        )
      ),
    );
  }
}

class _ConnectMainScreen extends StatefulWidget {
  const _ConnectMainScreen({
    @required this.bleProvider,
    @required this.floowerConnector,
    Key key
  }) : assert(bleProvider != null),
        super(key: key);

  final BleProvider bleProvider;
  final FloowerConnectorBle floowerConnector;

  @override
  _ConnectMainScreenState createState() {
    return _ConnectMainScreenState();
  }
}

class _ConnectMainScreenState extends State<_ConnectMainScreen> {

  FloowerScanner _floowerScanner;

  bool _skipInstructions = false;
  DiscoveredDevice _device;

  @override
  void initState() {
    _floowerScanner = FloowerScanner(
      bleProvider: widget.bleProvider,
      autoConnectDelay: Duration(seconds: 3),
      onAutoConnect: _onScannerAutoConnect
    );
    _floowerScanner.addListener(_onScannerChange);
    widget.floowerConnector.addListener(_onFloowerConnectorChange);
    super.initState();
  }

  @override
  void dispose() {
    widget.floowerConnector.removeListener(_onFloowerConnectorChange);
    _floowerScanner?.dispose();
    super.dispose();
  }

  void _startScanning() {
    assert(widget.bleProvider.status == BleStatus.ready);
    _floowerScanner.startScanning();
  }

  Future<void> _stopScanning() async {
    await _floowerScanner.stopScanning();
  }

  void _cancelScanning() async {
    await _stopScanning();
  }

  void _onScannerChange() {
    if (_floowerScanner.state == FloowerScannerState.timeouted) {
      if (_floowerScanner.discoveredDevices.isEmpty) {
        _noDeviceFound();
      }
      setState(() {});
    }
    else if (_floowerScanner.state == FloowerScannerState.finished) {
      setState(() => _skipInstructions = _floowerScanner.discoveredDevices.length > 1);
    }
    else {
      setState(() {});
    }
  }

  void _onScannerAutoConnect(DiscoveredDevice device) {
    if (!_skipInstructions) {
      _connectToDevice(device);
    }
  }

  Future<void> _connectToDevice(DiscoveredDevice device) async {
    await _stopScanning();
    widget.floowerConnector.connect(device.id, pairingColor: FloowerColor.COLOR_YELLOW.hwColor);
    setState(() {
      _device = device;
      _skipInstructions = true;
    });
  }

  void _onDemo(context) {
    Provider.of<FloowerModel>(context, listen: false).connect(FloowerConnectorDemo());
    Navigator.popUntil(context, ModalRoute.withName(HomeRoute.ROUTE_NAME));
  }

  void _onFloowerConnectorChange() {
    print("_onFloowerConnectorChange ${widget.floowerConnector.state}");
    setState(() {});
  }

  Future<bool> _disconnect() async {
    await widget.floowerConnector.disconnect();
    setState(() => _device = null);
    return true;
  }

  void _onReconnect(BuildContext context) {
    _connectToDevice(_device);
  }

  void _onPair(BuildContext context) async {
    FloowerModel floowerModel = Provider.of<FloowerModel>(context, listen: false);
    PersistentStorage persistentStorage = Provider.of<PersistentStorage>(context, listen: false);

    await widget.floowerConnector.pair();
    floowerModel.connect(widget.floowerConnector);
    persistentStorage.pairedDevice = widget.floowerConnector.deviceId;

    Navigator.popUntil(context, ModalRoute.withName(HomeRoute.ROUTE_NAME));
  }

  @override
  Widget build(BuildContext context) {
    // TODO: connecting screen
    if (_device != null) {
      Widget screen;
      switch (widget.floowerConnector.state) {
        case FloowerConnectionState.connecting:
        case FloowerConnectionState.connected:
          screen = FloowerConnecting(
              onCancel: _disconnect
          );
          break;

        case FloowerConnectionState.pairing:
        case FloowerConnectionState.paired:
          screen = FloowerConnected(
              onCancel: _disconnect,
              onPair: () => _onPair(context),
              color: FloowerColor.COLOR_YELLOW.displayColor
          );
          break;

        case FloowerConnectionState.disconnecting:
        case FloowerConnectionState.disconnected:
          screen = FloowerConnectFailed(
              message: widget.floowerConnector.connectionFailureMessage,
              onCancel: _disconnect,
              onReconnect: () => _onReconnect(context)
          );
          break;
      }

      return WillPopScope(
        onWillPop: _disconnect,
        child: screen,
      );
    }
    else if (_floowerScanner.discoveredDevices.length > 1 || _skipInstructions) {
      return BleScanList(
          discoveredDevices: _floowerScanner.discoveredDevices,
          scanIsInProgress: _floowerScanner.state == FloowerScannerState.scanning,
          onScanStart: _startScanning,
          onScanStop: _stopScanning,
          onDeviceConnect: (device) => _connectToDevice(device)
      );
    }
    else if (_floowerScanner.state == FloowerScannerState.scanning) {
      return BleScanning(
          onCancel: _cancelScanning
      );
    }
    else {
      return BleConnectInstructions(
          onStartScan: _startScanning,
          onDemo: () => _onDemo(context),
      );
    }
  }

  void _noDeviceFound() {
    showCupertinoDialog(
      context: context,
      builder: (context) => new CupertinoAlertDialog(
        title: Text("No Floower discovered"),
        content: Text("What to do now?\nCheck if your Floower is activated, move it closer to the device, or contact us!"),
        actions: <Widget>[
          new CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(),
              child: new Text("OK"))
        ],
      ),
    );
  }
}
