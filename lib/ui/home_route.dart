import 'dart:math';

import 'package:Floower/ui/connect/connect_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:Floower/logic/floower_model.dart';
import 'package:Floower/ui/connect/discover_route.dart';
import 'package:Floower/ui/settings/settings_route.dart';

class HomeRoute extends StatelessWidget {
  static const ROUTE_NAME = '/';

  @override
  Widget build(BuildContext context) {
    FloowerModel floowerModel = Provider.of<FloowerModel>(context);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: CupertinoTheme.of(context).brightness == Brightness.dark
            ? Image.asset('assets/images/floower-logo-white.png', height: 18)
            : Image.asset('assets/images/floower-logo-black.png', height: 18),
        trailing: floowerModel.connected
          ? GestureDetector(
            child: Icon(CupertinoIcons.gear),
            onTap: () => Navigator.pushNamed(context, SettingsRoute.ROUTE_NAME),
          )
          : Container(width: 0, height: 0)
      ),
      child: SafeArea(
        child: _Floower(),
      ),
    );
  }
}

class _Floower extends StatelessWidget {

  _Floower({ Key key }) : super(key: key);

  void _onConnectPressed(BuildContext context) {
    Navigator.pushNamed(context, DiscoverRoute.ROUTE_NAME);
  }

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
    final MediaQueryData data = MediaQuery.of(context);
    FloowerModel floowerModel = Provider.of<FloowerModel>(context);

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
              child: !floowerModel.connected ? Container(
                padding: EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                  color: CupertinoTheme.of(context).scaffoldBackgroundColor,
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
              ) : null,
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
                  ),
                ),
                onTap: () => floowerModel.togglePetals(),
              ) : SizedBox.shrink(),
            ),
            Positioned(
              right: 20,
              bottom: 20,
              child: _BatteryLevelIndicator(),
            ),
            Visibility(
            visible: !floowerModel.connected,
              child: Positioned(
                right: 15,
                bottom: 15,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                    color: CupertinoTheme.of(context).scaffoldBackgroundColor,
                  ),
                  child: CupertinoButton(
                    child: Text("Find out more"),
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

    if (level == 100) {
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