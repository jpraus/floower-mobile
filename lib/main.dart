import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'package:Floower/ble/ble_provider.dart';
import 'package:Floower/logic/floower_model.dart';
import 'package:Floower/logic/floower_connector.dart';
import 'package:Floower/logic/persistent_storage.dart';
import 'package:Floower/ui/connect/connect_route.dart';
import 'package:Floower/ui/settings/settings_route.dart';
import 'package:Floower/ui/home_route.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // This app is designed only to work vertically, so we limit
  // orientations to portrait up and down.
  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);

  final ble = FlutterReactiveBle();
  final bleProvider = BleProvider(ble);
  final floowerConnector = FloowerConnectorBle(bleProvider);
  final floowerModel = FloowerModel();
  final persistentStorage = PersistentStorage();
  //ble.logLevel = LogLevel.verbose;

  // senty is error reporting service to capture crashes
  await SentryFlutter.init((options) => options.dsn = 'https://58901cccbba74b51b2dcacc9fb1cdd71@o553961.ingest.sentry.io/5681891',
    appRunner: () => runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<BleProvider>.value(value: bleProvider),
          ChangeNotifierProvider<FloowerModel>.value(value: floowerModel),
          ChangeNotifierProvider<FloowerConnectorBle>.value(value: floowerConnector),
          ChangeNotifierProvider<PersistentStorage>.value(value: persistentStorage)
        ],
        child: CupertinoApp(
          title: 'Floower',
          theme: CupertinoThemeData(
            primaryColor: CupertinoColors.activeBlue,
            //brightness: Brightness.dark
            //brightness: Brightness.light
          ),
          localizationsDelegates: <LocalizationsDelegate<dynamic>>[
            DefaultMaterialLocalizations.delegate,
            DefaultCupertinoLocalizations.delegate,
            DefaultWidgetsLocalizations.delegate,
          ],
          debugShowCheckedModeBanner: false,
          initialRoute: HomeRoute.ROUTE_NAME,
          routes: {
            HomeRoute.ROUTE_NAME: (context) => HomeRoute(),
            ConnectRoute.ROUTE_NAME: (context) => ConnectRoute(),
            SettingsRoute.ROUTE_NAME: (context) => SettingsRoute()
          },
        ),
      ),
    )
  );
}