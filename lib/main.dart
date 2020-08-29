import 'package:flutter/cupertino.dart';
//import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_circle_color_picker/flutter_circle_color_picker.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'ble/ble_scanner.dart';
import 'FloowerModel.dart';
import 'ConnectRoute.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // This app is designed only to work vertically, so we limit
  // orientations to portrait up and down.
  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);

  final _ble = FlutterReactiveBle();
  _ble.logLevel = LogLevel.verbose;

  //final _scanner = BleScanner(_ble);
  //final _monitor = BleStatusMonitor(_ble);
  //final _connector = BleDeviceConnector(_ble);
  runApp(
    MultiProvider(
      providers: [
        Provider.value(value: _ble),
        StreamProvider<BleStatus>(
          create: (_) => _ble.statusStream,
          initialData: BleStatus.unknown,
        ),
        //Provider.value(value: _scanner),
        //Provider.value(value: _monitor),
        //Provider.value(value: _connector),
        /*StreamProvider<BleScannerState>(
          create: (_) => _scanner.state,
          initialData: const BleScannerState(
            discoveredDevices: [],
            scanIsInProgress: false,
          ),
        ),
        StreamProvider<ConnectionStateUpdate>(
          create: (_) => _connector.state,
          initialData: const ConnectionStateUpdate(
            deviceId: 'Unknown device',
            connectionState: DeviceConnectionState.disconnected,
            failure: null,
          ),
        ),*/
      ],
      child: CupertinoApp(
        title: 'Floower',

        theme: CupertinoThemeData(
          primaryColor: CupertinoColors.activeBlue,
        ),
        initialRoute: HomeRoute.ROUTE_NAME,
        routes: {
          ConnectRoute.ROUTE_NAME: (context) => ConnectRoute(),
          HomeRoute.ROUTE_NAME: (context) => HomeRoute()
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
        middle: Image.asset('assets/images/floower.png'),
        trailing: GestureDetector(
          child: Icon(CupertinoIcons.gear),
          onTap: () {
            Navigator.pushNamed(context, ConnectRoute.ROUTE_NAME);
          },
        ),
      ),
      child: SafeArea(
        child: ChangeNotifierProvider(
          create: (context) => FloowerModel(),
          child: Floower()
        ),
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

    return Column(
      children: <Widget>[
        Consumer<FloowerModel>(
          builder: (context, model, child) {
            return Container(
              decoration: BoxDecoration(
                color: model.color
              ),
              height: 40,
            );
          }
        ),
        Expanded (
          child: Stack(
            children: <Widget>[
              Container(
                padding: EdgeInsets.only(top: 40, bottom: 20),
                alignment: Alignment.center,
                constraints: BoxConstraints.expand(),
                child: FittedBox(
                  fit: BoxFit.fill,
                  child: Image(
                    image: AssetImage("assets/images/siluet.png"),
                  ),
                ),
              ),
              Container(
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
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _onColorPickerChanged(Color color) {
  }
}
