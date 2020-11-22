import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:Floower/ble/ble_provider.dart';
import 'package:Floower/logic/floower_model.dart';
import 'package:Floower/logic/floower_connector.dart';
import 'package:Floower/ui/connect/discover_route.dart';
import 'package:Floower/ui/settings/settings_route.dart';
import 'package:Floower/ui/home_route.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // This app is designed only to work vertically, so we limit
  // orientations to portrait up and down.
  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);

  final ble = FlutterReactiveBle();
  final bleProvider = BleProvider(ble);
  final floowerConnector = FloowerConnector(bleProvider);
  final floowerModel = FloowerModel(floowerConnector);
  //floowerModel.mock();
  ble.logLevel = LogLevel.verbose;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<BleProvider>.value(value: bleProvider),
        ChangeNotifierProvider<FloowerModel>.value(value: floowerModel),
        ChangeNotifierProvider<FloowerConnector>.value(value: floowerConnector),
        Provider.value(value: ble)
      ],
      child: CupertinoApp(
        title: 'Floower',
        theme: CupertinoThemeData(
          primaryColor: CupertinoColors.activeBlue,
          //brightness: Brightness.dark
          brightness: Brightness.light
        ),
        debugShowCheckedModeBanner: false,
        initialRoute: HomeRoute.ROUTE_NAME,
        routes: {
          HomeRoute.ROUTE_NAME: (context) => HomeRoute(),
          DiscoverRoute.ROUTE_NAME: (context) => DiscoverRoute(),
          SettingsRoute.ROUTE_NAME: (context) => SettingsRoute()
        },
      ),
    ),
  );
}