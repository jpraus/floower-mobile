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
import 'ui/connect_route.dart';

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
        ChangeNotifierProvider<FloowerModel>(
            create: (context) => floowerModel
        ),
        ChangeNotifierProvider<FloowerConnector>(
            create: (context) => floowerConnector
        ),
        Provider.value(value: ble),
        /*StreamProvider<BleStatus>(
          create: (_) => ble.statusStream,
          initialData: BleStatus.unknown,
        ),*/
      ],
      child: CupertinoApp(
        title: 'Floower',
        theme: CupertinoThemeData(
          primaryColor: CupertinoColors.activeBlue
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
          //child: Icon(CupertinoIcons.loop_thick),
          child: Icon(CupertinoIcons.gear),
          onTap: () {
            Navigator.pushNamed(context, ConnectRoute.ROUTE_NAME);
          },
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
              CupertinoButton.filled(
                child: Text("Open / Close"),
                onPressed: () => Provider.of<FloowerModel>(context, listen: false).setOpen(),
              )
            ],
          ),
        ),
      ],
    );
  }

  void _onColorPickerChanged(Color color) {
  }
}
