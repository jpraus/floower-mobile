import 'dart:async';

import 'package:Floower/ui/connect/connect_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:meta/meta.dart';
import 'package:provider/provider.dart';
import 'package:system_setting/system_setting.dart';

import 'package:Floower/ui/commons.dart';
import 'package:Floower/ble/ble_scanner.dart';
import 'package:Floower/ui/connect/device.dart';
import 'package:Floower/ui/connect/connect_layout.dart';
import 'package:Floower/ui/cupertino_list.dart';

class DiscoverRoute extends StatelessWidget {
  static const ROUTE_NAME = '/discover';

  @override
  Widget build(BuildContext context) {
    //final DiscoverRouteArguments args = ModalRoute.of(context).settings.arguments;

    return CupertinoPageScaffold(
      backgroundColor: CupertinoTheme.of(context).barBackgroundColor,
      navigationBar: CupertinoNavigationBar(
        middle: Text('Connect Your Floower'),
      ),
      child: SafeArea(
        child: _DiscoverScreen(
          ble: Provider.of<FlutterReactiveBle>(context, listen: false),
          //scanList: args?.scanList == true
        ),
      ),
    );
  }
}

class DiscoverRouteArguments {
  final bool scanList;
  DiscoverRouteArguments(this.scanList);
}

class _DiscoverScreen extends StatefulWidget {
  const _DiscoverScreen({
    @required this.ble,
    this.scanList = false,
    Key key
  }) : assert(ble != null),
        super(key: key);

  final FlutterReactiveBle ble;
  final bool scanList;

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
  bool floowerActivated = false;

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

  @override
  Widget build(BuildContext context) {
    switch (_bleStatus) {
      case BleStatus.ready:
        // scan screen
        return _ScanScreen(ble: widget.ble, scanList: widget.scanList);

      case BleStatus.poweredOff:
        // BLE off screen
        return _buildBluetoothUnavailableScreen(
          title: 'Bluetooth is OFF',
          message: 'Please turn on Bluetooth in order to discover near-by Floowers and connect with them.',
          buttonText: 'Turn it ON',
          onButtonPressed: () => SystemSetting.goto(SettingTarget.BLUETOOTH)
        );

      case BleStatus.locationServicesDisabled:
        // location service off screen
        return _buildBluetoothUnavailableScreen(
            title: 'Location Service is OFF',
            message: 'Please turn on Location service in order to discover near-by Floowers and connect with them.',
            buttonText: 'Turn it ON',
            onButtonPressed: () => SystemSetting.goto(SettingTarget.LOCATION)
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
    this.scanList = false,
    Key key
  }) : assert(ble != null),
        super(key: key);

  final FlutterReactiveBle ble;
  final bool scanList;

  @override
  _ScanScreenState createState() {
    return _ScanScreenState();
  }
}

class _ScanScreenState extends State<_ScanScreen> {

  BleScanner _bleScanner;
  StreamSubscription<BleScannerState> _bleScannerStateSubscription;
  BleScannerState _bleScannerState = const BleScannerState(
    discoveredDevices: [],
    scanIsInProgress: false,
  );
  Timer _tryConnectTimer;

  bool _scanningStarted = false;

  @override
  void initState() {
    _bleScanner = BleScanner(widget.ble);
    _bleScannerStateSubscription = _bleScanner.state
        .listen(_onScannerState);
    //_startScanning();
    super.initState();
  }

  @override
  void dispose() {
    _bleScannerStateSubscription?.cancel();
    _bleScanner?.dispose();
    super.dispose();
  }

  void _onScannerState(BleScannerState state) {
    this.setState(() {
      _bleScannerState = state;
      if (_tryConnectTimer?.isActive == false && state.scanIsInProgress == true && state.discoveredDevices.isNotEmpty) {
        print("Try connect");
        _tryConnectTimer = Timer(Duration(seconds: 3), _tryConnect);
      }
      if (state.timeOuted == true && state.discoveredDevices.isEmpty) {
        _noDeviceFound();
      }
    });
  }

  void _startScanning() {
    _bleScanner.startScan(
      serviceIds: [],
      timeout: Duration(seconds: 5)
    );
    _scanningStarted = true;
    _tryConnectTimer?.cancel();
  }

  void _tryConnect() {
    if (_bleScannerState.discoveredDevices.length == 1) {
      _connectToDevice(_bleScannerState.discoveredDevices[0]);
    }
  }

  void _stopScanning() {
    _bleScanner.stopScan();
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

  void _connectToDevice(DiscoveredDevice device) async {
    _stopScanning();
    Navigator.pushNamed(
      context,
      ConnectRoute.ROUTE_NAME,
      arguments: ConnectRouteArguments(device),
    );
  }

  void _onCancel(BuildContext context) {
    _stopScanning();
    Navigator.pop(context); // back to scan screen
  }

  @override
  Widget build(BuildContext context) {
    print(_scanningStarted);
    if (_bleScannerState.discoveredDevices.length > 1 || (widget.scanList && _bleScannerState.scanIsInProgress)) {
      return _buildScanList();
    }
    else if (_bleScannerState.scanIsInProgress) {
      return _buildSearchingScreen();
    }
    else {
      return _buildTouchLeafScreen();
    }
  }

  Widget _buildTouchLeafScreen() {
    return ConnectLayout(
      title: "Hold the Leaf",
      image: Image(
          fit: BoxFit.fitHeight,
          image: AssetImage("assets/images/leaf.png")
      ),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            constraints: BoxConstraints(maxWidth: 400),
            padding: EdgeInsets.only(bottom: 18, left: 20, right: 20),
            child: Text("Hold your Floower's leaf for 5 seconds until\nthe blossom starts flashing blue.", textAlign: TextAlign.center),
          ),
          CupertinoButton.filled(
              child: Text("It's flashing now"),
              onPressed: () => _startScanning()
          ),
          CupertinoButton(
              child: Text("Cancel"),
              onPressed: () => _onCancel(context)
          )
        ],
      ),
      animationBuilder: (centerOffset, imageSize) => TouchHandAnimation(
        centerOffset: centerOffset,
        imageSize: imageSize,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Widget _buildSearchingScreen() {
    return ConnectLayout(
      title: "Searching ...",
      image: Image(
          fit: BoxFit.fitHeight,
          image: AssetImage("assets/images/floower-blossom.png")
      ),
      trailing: CupertinoButton(
        child: Text("Cancel"),
        onPressed: () => _onCancel(context)
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
            centerOffset: centerOffset,
            key: new ObjectKey(this)
        );
      },
    );
  }

  Widget _buildScanList() {
    List<Widget> column = [];

    // discovered devices
    List<Widget> discoveredDevices = [];
    for (DiscoveredDevice device in _bleScannerState.discoveredDevices) {
      discoveredDevices.add(new DiscoveredDeviceListItem(
          device: device,
          onTap: _connectToDevice
      ));
    }

    column.add(CupertinoList(
      margin: EdgeInsets.only(top: 18),
      heading: GestureDetector(
        child: Row(
          children: <Widget>[
            Text(_bleScannerState.scanIsInProgress ? "SCANNING FOR DEVICES" : "DISCOVERED DEVICES", style: FloowerTextTheme.listLabel),
            const SizedBox(width: 10),
            _bleScannerState.scanIsInProgress ? CupertinoActivityIndicator() : Icon(CupertinoIcons.refresh),
          ],
        ),
        onTap: _bleScannerState.scanIsInProgress ? _stopScanning : _startScanning,
      ),
      //hint: discoveredDevices.isNotEmpty ? const Text("Tap the device to connect", style: FloowerTextTheme.listLabel) : null,
      children: discoveredDevices
    ));

    return ListView(
      children: column,
    );
  }
}

class TouchHandAnimation extends StatefulWidget {

  final Duration duration;
  final double imageSize;
  final Offset centerOffset;

  TouchHandAnimation({
    @required this.duration,
    @required this.imageSize,
    @required this.centerOffset,
    Key key
  }) : super(key: key);

  @override
  TouchHandAnimationState createState() => TouchHandAnimationState();
}

class TouchHandAnimationState extends State<TouchHandAnimation> with SingleTickerProviderStateMixin {

  Animation<double> _touchAnimation;
  AnimationController _controller;
  bool _forward = true;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _touchAnimation = Tween<double>(begin: widget.imageSize / 2, end: widget.imageSize / 2.4).animate(_controller);
    _touchAnimation.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _controller.reverse();
      }
      if (status == AnimationStatus.dismissed) {
        _controller.reset();
        _controller.forward();
      }
    });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Positioned( // using magic constants
            left: widget.centerOffset.dx - _touchAnimation.value,
            top: widget.centerOffset.dy - _touchAnimation.value,
            child: Transform(
              transform: Matrix4.rotationZ(0.3),
              alignment: Alignment.center,
              child: Image(
                width: widget.imageSize / 1.5,
                image: AssetImage("assets/images/touch_hand.png")
              ),
            )
          );
        }
    );
  }
}

class _DrawCenteredCircle extends CustomPainter {

  final Offset centerOffset;
  final double radius;
  final Color color;

  _DrawCenteredCircle({this.radius, this.color, this.centerOffset});

  @override
  void paint(Canvas canvas, Size size) {
    Paint brush = new Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.fill
      ..strokeWidth = 30;
    canvas.drawCircle(centerOffset, radius, brush);
  }

  @override
  bool shouldRepaint(_DrawCenteredCircle oldDelegate) {
    return oldDelegate.radius != radius || oldDelegate.color != color;
  }
}