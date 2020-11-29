import 'dart:math';
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:Floower/logic/floower_color.dart';
import 'package:Floower/logic/floower_model.dart';
import 'package:Floower/logic/floower_connector.dart';
import 'package:Floower/ble/ble_provider.dart';
import 'package:Floower/logic/persistent_storage.dart';
import 'package:Floower/ui/connect/connect_route.dart';
import 'package:Floower/ui/settings/settings_route.dart';

class HomeRoute extends StatelessWidget {
  static const ROUTE_NAME = '/';

  @override
  Widget build(BuildContext context) {
    BleProvider bleProvider = Provider.of<BleProvider>(context);
    PersistentStorage persistentStorage = Provider.of<PersistentStorage>(context);
    FloowerModel floowerModel = Provider.of<FloowerModel>(context);
    FloowerConnectorBle floowerConnectorBle = Provider.of<FloowerConnectorBle>(context);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: CupertinoTheme.of(context).brightness == Brightness.dark
            ? Image.asset('assets/images/floower-logo-dark.png', height: 18)
            : Image.asset('assets/images/floower-logo-light.png', height: 18),
        trailing: floowerModel.connected
          ? GestureDetector(
            child: Icon(CupertinoIcons.gear),
            onTap: () => Navigator.pushNamed(context, SettingsRoute.ROUTE_NAME),
          )
          : Container(width: 0, height: 0)
      ),
      child: SafeArea(
        child: _Floower(
          persistentStorage: persistentStorage,
          bleProvider: bleProvider,
          floowerConnectorBle: floowerConnectorBle,
          floowerModel: floowerModel,
        ),
      ),
    );
  }
}

class _Floower extends StatelessWidget {

  final BleProvider bleProvider;
  final PersistentStorage persistentStorage;
  final FloowerConnectorBle floowerConnectorBle;
  final FloowerModel floowerModel;

  _Floower({
    this.bleProvider,
    this.persistentStorage,
    this.floowerConnectorBle,
    this.floowerModel,
    Key key
  }) : super(key: key);

  void _onColorPickerChanged(BuildContext context, FloowerColor color) {
    Provider.of<FloowerModel>(context, listen: false).setColor(color);
  }

  void _onPurchase() async {
    const url = 'https://floower.io';
    if (await canLaunch(url)) {
      await launch(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMediaQuery(context));

    return LayoutBuilder(
      builder: (context, constraints) {
        double refHeight = constraints.maxHeight;
        return Stack(
          children: <Widget>[
            Visibility(
              visible: floowerModel.connected && !floowerModel.color.isBlack(),
              child: Positioned(
                top: 8,
                right: 0,
                left: 0,
                child: Container(
                  alignment: Alignment.topCenter,
                  width: refHeight / 2.5,
                  height: refHeight / 2.5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [floowerModel.color.displayColor, floowerModel.color.displayColor, CupertinoTheme.of(context).scaffoldBackgroundColor],
                    )
                  ),
                ),
              ),
            ),
            Center(
              child: Image(
                image: floowerModel.connected
                  ? AssetImage("assets/images/floower-off.png")
                  : AssetImage("assets/images/floower-bw.png"),
              ),
            ),
            Center(
              child: _AutoConnect(
                persistentStorage: persistentStorage,
                bleProvider: bleProvider,
                floowerConnectorBle: floowerConnectorBle,
                floowerModel: floowerModel
              ),
            ),
            Positioned(
              left: 14,
              top: 14,
              child: _ColorPicker(
                maxHeight: constraints.maxHeight - 28, // padding
                onSelect: (color) => _onColorPickerChanged(context, color),
              ),
            ),
            Positioned(
              top: refHeight / 2.1,
              left: constraints.maxWidth / 2,
              child: floowerModel.connected ? GestureDetector(
                child: Transform.rotate(
                  //angle: -0.8,
                  angle: 0,
                  child: Container(
                    width: refHeight / 4.5,
                    height: refHeight / 3.5,
                    color: Colors.transparent,
                    //color: Colors.blue
                  ),
                ),
                onTap: () => floowerModel.togglePetals(),
              ) : SizedBox.shrink(),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Center(
                child: floowerModel.connected ? GestureDetector(
                  child: Transform.rotate(
                    //angle: -0.8,
                    angle: 0,
                    child: Container(
                        width: refHeight / 4,
                        height: refHeight / 3,
                        color: Colors.transparent,
                        //color: Colors.blue
                    ),
                  ),
                  onTap: () => floowerModel.togglePetals(),
                ) : SizedBox.shrink(),
              )
            ),
            Visibility(
              visible: floowerModel.connected && !floowerModel.demo,
              child: Positioned(
                right: 20,
                bottom: 20,
                child: _BatteryLevelIndicator(),
              ),
            ),
            Visibility(
              visible: !floowerModel.connected || floowerModel.demo,
              child: Positioned(
                right: 15,
                bottom: 15,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                    color: CupertinoTheme.of(context).scaffoldBackgroundColor,
                  ),
                  child: CupertinoButton(
                    child: Text("Get Floower"),
                    onPressed: _onPurchase,
                  ),
                )
              )
            )
          ],
        );
      },
    );
  }
}

class _ColorPicker extends StatelessWidget {

  final double maxHeight;
  final void Function(FloowerColor color) onSelect;

  _ColorPicker({this.maxHeight, this.onSelect});

  @override
  Widget build(BuildContext context) {
    FloowerModel floowerModel = Provider.of<FloowerModel>(context);

    return FutureBuilder<List<FloowerColor>>(
      future: floowerModel.getColorsScheme(),
      builder: _buildColorPicker,
      initialData: [],
    );
  }

  Widget _buildColorPicker(BuildContext context, AsyncSnapshot<List<FloowerColor>> snapshot) {
    if (!snapshot.hasData || snapshot.data.isEmpty) {
      return SizedBox(width: 0, height: 0);
    }

    Color borderColor = CupertinoTheme.of(context).brightness == Brightness.light ? Colors.black : Colors.white;

    double circleSize = min(maxHeight / (snapshot.data.length + 1), 70);
    List<Widget> items = snapshot.data.map((color) => GestureDetector(
      child: Container(
        width: circleSize - 8,
        height: circleSize - 8,
        margin: EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.displayColor,
          border: Border.all(color: borderColor.withOpacity(color.isLight() ? 0.1 : 0))
        ),
      ),
      onTap: () => onSelect(color),
    )).toList();

    items.add(GestureDetector(
      child: Container(
        width: circleSize - 8,
        height: circleSize - 8,
        margin: EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
            border: Border.all(color: borderColor.withOpacity(0.4))
        ),
        child: Icon(Icons.power_settings_new, color: borderColor),
      ),
      onTap: () => onSelect(FloowerColor.black)
    ));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: items,
    );
  }
}

class _BatteryLevelIndicator extends StatefulWidget {
  _BatteryLevelIndicator({Key key}) : super(key: key);

  @override
  _BatteryLevelIndicatorState createState() => _BatteryLevelIndicatorState();
}

class _BatteryLevelIndicatorState extends State<_BatteryLevelIndicator> with SingleTickerProviderStateMixin {
  AnimationController _animationController;

  @override
  void initState() {
    _animationController = new AnimationController(vsync: this, duration: Duration(seconds: 1));
    _animationController.repeat();
    super.initState();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    FloowerModel floowerModel = Provider.of<FloowerModel>(context);
    int level = floowerModel.batteryLevel;
    Widget icon;

    if (level < 0 || !floowerModel.connected) {
      return Container();
    }

    if (floowerModel.batteryCharging) {
      icon = Icon(CupertinoIcons.battery_charging);
    }
    else if (level > 75) {
      icon = Icon(CupertinoIcons.battery_full);
    }
    else if (level > 50) {
      icon = Icon(CupertinoIcons.battery_75_percent);
    }
    else if (level > 25) {
      icon = Icon(CupertinoIcons.battery_25_percent);
    }
    else {
      icon = FadeTransition(
        child: Icon(CupertinoIcons.battery_empty, color: Colors.red),
        opacity: _animationController,
      );
    }

    return Container(
      color: CupertinoTheme.of(context).scaffoldBackgroundColor,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(width: 5),
          icon,
          SizedBox(width: 5),
          Text("$level%")
        ],
      ),
    );
  }
}

class _AutoConnect extends StatefulWidget {

  final PersistentStorage persistentStorage;
  final BleProvider bleProvider;
  final FloowerConnectorBle floowerConnectorBle;
  final FloowerModel floowerModel;

  _AutoConnect({
    @required this.persistentStorage,
    @required this.bleProvider,
    @required this.floowerConnectorBle,
    @required this.floowerModel,
    Key key
  }) : super(key: key);

  @override
  _AutoConnectState createState() => _AutoConnectState();
}

class _AutoConnectState extends State<_AutoConnect> {

  bool _ready = false;
  bool _connecting = false;
  bool _connectingFailed = false;
  bool _connected = false;
  Timer _connectTimer;

  @override
  void initState() {
    widget.bleProvider.addListener(_onBleProviderChange);
    widget.floowerModel.addListener(_onFloowerModelChange);
    _connected = widget.floowerModel.connected;
    _connecting = widget.floowerModel.connecting;
    super.initState();
  }

  @override
  void dispose() {
    widget.bleProvider.removeListener(_onBleProviderChange);
    widget.floowerModel.removeListener(_onFloowerModelChange);
    _connectTimer?.cancel();
    super.dispose();
  }

  void _onBleProviderChange() async {
    if (widget.bleProvider.ready && !_ready) {
      setState(() => _ready = true);
      _tryConnect();
    }
  }

  void _onFloowerModelChange() {
    setState(() {
      _connected = widget.floowerModel.connected;
      _connectingFailed = _connectingFailed || (_connecting && widget.floowerModel.disconnected);
      _connecting = widget.floowerModel.connecting;
    });
  }

  void _tryConnect() async {
    if (widget.floowerModel.disconnected) {
      String deviceId = widget.persistentStorage.pairedDevice;
      if (deviceId != null) {
        print("Attempting connect to device $deviceId");
        setState(() => _connecting = true);
        await widget.floowerConnectorBle.connect(deviceId);
        widget.floowerModel.connect(widget.floowerConnectorBle);
      }
    }
    _connectTimer?.cancel();
    _connectTimer = Timer(Duration(seconds: 5), _tryConnect);
  }

  void _onConnectPressed(BuildContext context) {
    Navigator.pushNamed(context, ConnectRoute.ROUTE_NAME);
  }

  void _onCancelPressed() {
    widget.floowerModel.disconnect();
  }

  @override
  Widget build(BuildContext context) {
    if (_connecting && !_connectingFailed) {
      return Container(
        padding: EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          color: CupertinoTheme.of(context).scaffoldBackgroundColor,
        ),
        child: GestureDetector(
            onTap: _onCancelPressed,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Connecting ..."),
                SizedBox(height: 21),
                CupertinoActivityIndicator(radius: 20),
              ],
            )
        )
      );
    }
    else if (!_connected) {
      return Container(
        padding: EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          color: CupertinoTheme
              .of(context)
              .scaffoldBackgroundColor,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Not connected"),
            SizedBox(height: 18),
            CupertinoButton.filled(
              child: Text("Connect"),
              onPressed: () => _onConnectPressed(context),
            ),
          ],
        )
      );
    }
    else {
      return Container();
    }
  }
}