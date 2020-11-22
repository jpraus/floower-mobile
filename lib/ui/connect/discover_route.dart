import 'dart:async';

import 'package:Floower/ui/connect/connect_widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:meta/meta.dart';
import 'package:provider/provider.dart';

import 'package:Floower/ble/ble_provider.dart';
import 'package:Floower/logic/floower_scanner.dart';
import 'package:Floower/logic/floower_connector.dart';
import 'package:Floower/ui/home_route.dart';
import 'package:Floower/ui/connect/discover_widgets.dart';
import 'package:Floower/ui/connect/ble_enabler.dart';

class DiscoverRoute extends StatelessWidget {
  static const ROUTE_NAME = '/discover';

  @override
  Widget build(BuildContext context) {
    BleProvider bleProvider = Provider.of<BleProvider>(context);
    FloowerConnector floowerConnector = Provider.of<FloowerConnector>(context);

    return CupertinoPageScaffold(
      //backgroundColor: CupertinoTheme.of(context).barBackgroundColor,
      navigationBar: CupertinoNavigationBar(
        middle: Text('Connect Your Floower'),
      ),
      child: SafeArea(
        child: BleEnabler(
          bleProvider: bleProvider,
          readyChild: new _DiscoverScreen(
            bleProvider: bleProvider,
            floowerConnector: floowerConnector
          ),
        )
      ),
    );
  }
}

class _DiscoverScreen extends StatefulWidget {
  const _DiscoverScreen({
    @required this.bleProvider,
    @required this.floowerConnector,
    Key key
  }) : assert(bleProvider != null),
        super(key: key);

  final BleProvider bleProvider;
  final FloowerConnector floowerConnector;

  @override
  _DiscoverScreenState createState() {
    return _DiscoverScreenState();
  }
}

class _DiscoverScreenState extends State<_DiscoverScreen> {

  FloowerScanner _floowerScanner;

  bool _skipInstructions = false;
  String _failedMessage;
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
    widget.floowerConnector.connect(device, FloowerConnector.COLOR_YELLOW.hwColor);
    setState(() {
      _device = device;
      _skipInstructions = true;
    });
  }

  void _onFloowerConnectorChange() {
    print("_onFloowerConnectorChange ${widget.floowerConnector.connectionState}");
    setState(() {});
  }

  Future<bool> _disconnect() async {
    await widget.floowerConnector.disconnect();
    setState(() => _device = null);
  }

  void _onReconnect(BuildContext context) {
    _connectToDevice(_device);
  }

  void _onPair(BuildContext context) async {
    await widget.floowerConnector.writeState(openLevel: 0, color: Colors.black, duration: Duration(milliseconds: 500));
    widget.floowerConnector.pair();
    Navigator.popUntil(context, ModalRoute.withName(HomeRoute.ROUTE_NAME));
  }

  @override
  Widget build(BuildContext context) {
    // TODO: connecting screen
    if (_device != null) {
      Widget screen;
      switch (widget.floowerConnector.connectionState) {
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
              color: FloowerConnector.COLOR_YELLOW.displayColor
          );
          break;

        case FloowerConnectionState.disconnecting:
        case FloowerConnectionState.disconnected:
          screen = FloowerConnectFailed(
              message: _failedMessage,
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
          onStartScan: _startScanning
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
