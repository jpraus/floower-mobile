import 'package:Floower/logic/floower_connector.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
//import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_circle_color_picker/flutter_circle_color_picker.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'logic/floower_model.dart';
import 'logic/floower_connector.dart';
import 'ui/connect/discover_route.dart';
import 'ui/connect/connect_route.dart';
import 'ui/settings_route.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // This app is designed only to work vertically, so we limit
  // orientations to portrait up and down.
  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);

  final ble = FlutterReactiveBle();
  final floowerConnector = FloowerConnector(ble);
  final floowerModel = FloowerModel(floowerConnector);
  ble.logLevel = LogLevel.verbose;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<FloowerModel>.value(value: floowerModel),
        ChangeNotifierProvider<FloowerConnector>.value(value: floowerConnector),
        Provider.value(value: ble)
      ],
      child: CupertinoApp(
        title: 'Floower',
        theme: CupertinoThemeData(
          primaryColor: CupertinoColors.activeBlue
        ),
        initialRoute: HomeRoute.ROUTE_NAME,
        routes: {
          HomeRoute.ROUTE_NAME: (context) => HomeRoute(),
          DiscoverRoute.ROUTE_NAME: (context) => DiscoverRoute(),
          ConnectRoute.ROUTE_NAME: (context) => ConnectRoute(),
          SettingsRoute.ROUTE_NAME: (context) => SettingsRoute()
        },
      ),
    ),
  );
}

class HomeRoute extends StatelessWidget {
  static const ROUTE_NAME = '/';

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.white,
      navigationBar: CupertinoNavigationBar(
        middle: Image.asset('assets/images/floower-trnsp.png', height: 18),
        trailing: Consumer<FloowerModel>(
          builder: (context, model, child) {
            return model.connected
              ? GestureDetector(
                child: Icon(CupertinoIcons.gear),
                onTap: () => Navigator.pushNamed(context, SettingsRoute.ROUTE_NAME),
              )
              : Container(width: 0, height: 0);
          }
        ),
      ),
      child: SafeArea(
        child: Floower(),
      ),
    );
  }
}

class Floower extends StatelessWidget {

  const Floower({ Key key }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMediaQuery(context));
    final MediaQueryData data = MediaQuery.of(context);

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
            /*Container(
              alignment: Alignment.topCenter,
              child: CircleColorPicker(
                //initialColor: Colors.blue,
                size: const Size(250, 250), // TODO
                textStyle: const TextStyle(fontSize: 0),
                //strokeWidth: 16,
                //thumbSize: 36,
                onChanged: (color) => Provider.of<FloowerModel>(context, listen: false).setColor(color),
                //onChanged: _onColorPickerChanged
              ),
            ),*/
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
                      onPressed: () =>
                          Navigator.pushNamed(
                              context, DiscoverRoute.ROUTE_NAME),
                    ),
                  ],
                )
              ) : null,
            ),
          ],
        );
      },
    );
  }

  void _onColorPickerChanged(Color color) {
  }
}
