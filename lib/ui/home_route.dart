import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_circle_color_picker/flutter_circle_color_picker.dart';
import 'package:provider/provider.dart';

import 'package:Floower/logic/floower_model.dart';
import 'package:Floower/logic/floower_connector.dart';
import 'package:Floower/ui/connect/discover_route.dart';
import 'package:Floower/ui/settings_route.dart';

class HomeRoute extends StatelessWidget {
  static const ROUTE_NAME = '/';

  @override
  Widget build(BuildContext context) {
    FloowerModel floowerModel = Provider.of<FloowerModel>(context);

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.white,
      navigationBar: CupertinoNavigationBar(
        middle: Image.asset('assets/images/floower-trnsp.png', height: 18),
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

  const _Floower({ Key key }) : super(key: key);

  void _onConnectPressed(BuildContext context) {
    Navigator.pushNamed(context, DiscoverRoute.ROUTE_NAME);
  }

  void _onColorPickerChanged(Color color) {
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMediaQuery(context));
    final MediaQueryData data = MediaQuery.of(context);
    FloowerModel floowerModel = Provider.of<FloowerModel>(context);

    return Consumer<FloowerModel>(
      builder: (context, model, child) {
        return Stack(
          children: <Widget>[
            Center(
              child: Image(
                image: model.connected
                  ? AssetImage("assets/images/floower-off.png")
                  : AssetImage("assets/images/floower-bw.png"),
              ),
            ),
            Container(
              alignment: Alignment.topCenter,
              child: model.connected ? CircleColorPicker(
                //initialColor: Colors.blue,
                size: const Size(250, 250), // TODO
                textStyle: const TextStyle(fontSize: 0),
                strokeWidth: 16,
                //thumbSize: 36,
                onChanged: (color) => Provider.of<FloowerModel>(context, listen: false).setColor(color),
                //onChanged: _onColorPickerChanged
              ) : null,
            ),
            Center(
              child: !model.connected ? Container(
                padding: EdgeInsets.all(18),
                color: CupertinoColors.white,
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
              right: 20,
              bottom: 20,
              child: _BatteryLevelIndicator(),
            )
          ],
        );
      },
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

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        SizedBox(width: 5),
        Text("$level%")
      ],
    );
  }
}

