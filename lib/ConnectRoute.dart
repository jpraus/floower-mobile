import 'dart:async';

import 'package:flutter/cupertino.dart';
//import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:meta/meta.dart';
import 'package:provider/provider.dart';

import 'reactive_state.dart';
import 'BluetoothDeviceListEntry.dart';

class ConnectRoute extends StatelessWidget {
  static const ROUTE_NAME = '/connect';

  @override
  Widget build(BuildContext context) {
    return DeviceListScreen();
  }
}

class DeviceListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Consumer2<BleScanner, BleScannerState>(
        builder: (_, bleScanner, bleScannerState, __) => _DeviceList(
          scannerState: bleScannerState,
          startScan: bleScanner.startScan,
          stopScan: bleScanner.stopScan,
        ),
      );
}

class _DeviceList extends StatefulWidget {
  const _DeviceList(
      {@required this.scannerState,
      @required this.startScan,
      @required this.stopScan})
      : assert(scannerState != null),
        assert(startScan != null),
        assert(stopScan != null);

  final BleScannerState scannerState;
  final void Function(List<Uuid>) startScan;
  final VoidCallback stopScan;

  @override
  _DeviceListState createState() => _DeviceListState();
}

class _DeviceListState extends State<_DeviceList> {

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    widget.stopScan();
    super.dispose();
  }

  void _startScanning() {
    widget.startScan([]);
  }

  void _stopScanning() {
    widget.stopScan();
  }

  @override
  Widget build(BuildContext context) => CupertinoPageScaffold(
    //backgroundColor: Colors.grey.shade200,
    child: CustomScrollView(
      slivers: <Widget>[
        CupertinoSliverNavigationBar(
          largeTitle: widget.scannerState.scanIsInProgress
            ? Text('Discovering Floowers')
            : Text('Connect Your Floower'),
          trailing: widget.scannerState.scanIsInProgress
            ? GestureDetector(
              child: CupertinoActivityIndicator(
                radius: 15,
              ),
              onTap: _stopScanning,
            )
            : GestureDetector(
              child: Icon(CupertinoIcons.refresh_bold),
              onTap: _startScanning,
            ),
        ),
        SliverSafeArea(
          top: false,
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              if (index < widget.scannerState.discoveredDevices.length) {
                return new BluetoothDeviceListEntry(device: widget.scannerState.discoveredDevices[index]);
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
  );
}

class BleScanner extends ReactiveState<BleScannerState> {
  BleScanner(this._ble);

  final FlutterReactiveBle _ble;
  final StreamController<BleScannerState> _stateStreamController =
      StreamController();

  final _devices = <DiscoveredDevice>[];

  @override
  Stream<BleScannerState> get state => _stateStreamController.stream;

  void startScan(List<Uuid> serviceIds) {
    _devices.clear();
    _subscription?.cancel();
    _subscription =
        _ble.scanForDevices(withServices: serviceIds).listen((device) {
      final knownDeviceIndex = _devices.indexWhere((d) => d.id == device.id);
      if (knownDeviceIndex >= 0) {
        _devices[knownDeviceIndex] = device;
      } else {
        _devices.add(device);
      }
      _pushState();
    });
    _pushState();
  }

  void _pushState() {
    _stateStreamController.add(
      BleScannerState(
        discoveredDevices: _devices,
        scanIsInProgress: _subscription != null,
      ),
    );
  }

  Future<void> stopScan() async {
    await _subscription?.cancel();
    _subscription = null;
    _pushState();
  }

  Future<void> dispose() async {
    await _stateStreamController.close();
  }

  StreamSubscription _subscription;
}

@immutable
class BleScannerState {
  const BleScannerState({
    @required this.discoveredDevices,
    @required this.scanIsInProgress,
  });

  final List<DiscoveredDevice> discoveredDevices;
  final bool scanIsInProgress;
}
