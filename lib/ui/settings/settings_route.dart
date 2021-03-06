import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_xlider/flutter_xlider.dart';
import 'package:provider/provider.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

import 'package:Floower/ui/commons.dart';
import 'package:Floower/logic/persistent_storage.dart';
import 'package:Floower/logic/floower_model.dart';
import 'package:Floower/ui/home_route.dart';
import 'package:Floower/ui/cupertino_list.dart';
import 'package:Floower/ui/settings/settings_name_dialog.dart';
import 'package:Floower/ui/settings/settings_color_scheme.dart';
import 'package:package_info/package_info.dart';

class SettingsRoute extends StatelessWidget {
  static const ROUTE_NAME = '/settings';

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('Settings'),
      ),
      child: SafeArea(
        child: _SettingsScreen(),
      ),
    );
  }
}

class _SettingsScreen extends StatelessWidget {
  const _SettingsScreen({
    Key key
  }) : super(key: key);

  void _onDisconnect(BuildContext context) async {
    PersistentStorage persistentStorage = Provider.of<PersistentStorage>(context, listen: false);
    FloowerModel floowerModel = Provider.of<FloowerModel>(context, listen: false);

    await floowerModel.disconnect();
    await persistentStorage.removePairedDevice();
    Navigator.popUntil(context, ModalRoute.withName(HomeRoute.ROUTE_NAME));
  }

  void _onNameTap(BuildContext context) {
    showCupertinoModalBottomSheet(
      expand: true,
      context: context,
      builder: (context) => SettingNameDialog()
    );
  }

  @override
  Widget build(BuildContext context) {
    FloowerModel floowerModel = Provider.of<FloowerModel>(context);
    List<Widget> column = [];

    // connected devices
    column.add(const SizedBox(height: 35));
    column.add(CupertinoList(
      children: [
        CupertinoListItem(
          title: Text("Connected"),
          trailing: GestureDetector(
            child: Text("DISCONNECT", style: CupertinoTheme.of(context).textTheme.actionTextStyle),
            onTap: () => _onDisconnect(context),
          ),
        ),
        CupertinoListItem(
          title: Text("Name"),
          onTap: () => _onNameTap(context),
          trailing: Row(
            children: [
              Text(floowerModel.name, style: FloowerTextTheme.secondaryLabel(context)),
              Icon(CupertinoIcons.forward, color: FloowerTextTheme.secondaryColor()),
            ],
          ),
        ),
        /*CupertinoListItem(
          title: Text("Behavior"),
          trailing: Row(
            children: [
              const Text("Blooming Flower", style: TextStyle(color: CupertinoColors.tertiaryLabel)),
              const Icon(CupertinoIcons.forward, color: CupertinoColors.tertiaryLabel),
            ],
          ),
        ),*/
      ],
    ));

    // color scheme section
    column.add(ColorSchemePicker(
      floowerModel: floowerModel,
    ));

    // about sections
    if (floowerModel.firmwareVersion >= 7) {
      column.add(CupertinoList(
          margin: EdgeInsets.only(top: 35),
          heading: Text("Customization"),
          children: [
            CupertinoListItem(
              title: Text("Light Intensity"),
              paddingBottom: 11,
            ),
            CupertinoListItem(
              paddingTop: 0,
              leading: Icon(CupertinoIcons.sun_min,
                  color: FloowerTextTheme.secondaryColor()),
              title: PersonificationSlider(
                min: 5,
                max: 100,
                step: 1,
                value: floowerModel.colorBrightness?.toDouble(),
                onChanged: (value) => floowerModel.setColorBrightness(value.toInt()),
              ),
              trailing: Icon(CupertinoIcons.sun_max_fill,
                  color: FloowerTextTheme.secondaryColor()),
            ),
            CupertinoListItem(
              title: Text("Speed"),
              paddingBottom: 11,
            ),
            CupertinoListItem(
              paddingTop: 0,
              leading: Text(
                  "Slow", style: FloowerTextTheme.secondaryLabel(context)),
              title: PersonificationSlider(
                min: 5,
                max: 100,
                step: 1,
                value: 105 - floowerModel.speed?.toDouble(), // reversed slider
                onChanged: (value) => floowerModel.setSpeed(105 - value.toInt()),
              ),
              trailing: Text("Fast", style: FloowerTextTheme.secondaryLabel(context)),
            ),
            CupertinoListItem(
              title: Text("Petals Openness"),
              paddingBottom: 11,
            ),
            CupertinoListItem(
              paddingTop: 0,
              leading: Text("5%", style: FloowerTextTheme.secondaryLabel(context)),
              title: PersonificationSlider(
                min: 10,
                max: 100,
                step: 5,
                value: floowerModel.maxOpenLevel?.toDouble(),
                onChanged: (value) {
                  floowerModel.openPetals(level: value.toInt());
                  floowerModel.setMaxOpenLevel(value.toInt());
                },
              ),
              trailing: Text("100%", style: FloowerTextTheme.secondaryLabel(context)),
            ),
            CupertinoListItem(
              title: Text("Touch Sensitivity"),
              paddingBottom: 11,
            ),
            CupertinoListItem(
              paddingTop: 0,
              leading: Text(
                  "Low", style: FloowerTextTheme.secondaryLabel(context)),
              title: PersonificationSlider(
                min: 40,
                max: 50,
                step: 1,
                value: floowerModel.touchThreshold?.toDouble(),
                onChanged: (value) => floowerModel.setTouchThreshold(value.toInt()),
              ),
              trailing: Text("High", style: FloowerTextTheme.secondaryLabel(context)),
            ),
          ]
      ));
    }

    // about sections
    column.add(CupertinoList(
      margin: EdgeInsets.only(top: 35),
      heading: Text("About"),
      children: [
        CupertinoListItem(
          title: Text("Serial Number"),
          trailing: Text(floowerModel.serialNumber?.toString()?.padLeft(4, '0') ?? "", style: FloowerTextTheme.secondaryLabel(context)),
        ),
        CupertinoListItem(
          title: Text("Model"),
          trailing: Text(floowerModel.modelName ?? "", style: FloowerTextTheme.secondaryLabel(context)),
        ),
        CupertinoListItem(
          title: Text("Firmware Version"),
          trailing: Text(floowerModel.firmwareVersion?.toString() ?? "", style: FloowerTextTheme.secondaryLabel(context)),
        ),
        CupertinoListItem(
          title: Text("Hardware Version"),
          trailing: Text(floowerModel.hardwareRevision?.toString() ?? "", style: FloowerTextTheme.secondaryLabel(context)),
        ),
        CupertinoListItem(
          title: Text("App Version"),
          trailing: FutureBuilder(
            future: PackageInfo.fromPlatform(),
            builder: (BuildContext context, AsyncSnapshot<PackageInfo> snapshot) {
              return Text(snapshot.hasData ? snapshot.data.version : "?", style: FloowerTextTheme.secondaryLabel(context));
            },
          )
        ),
      ],
    ));

    return ListView(
      children: column
    );
  }
}

class PersonificationSlider extends StatelessWidget {

  final double min;
  final double max;
  final double value;
  final double step;
  final ValueChanged<double> onChanged;

  PersonificationSlider({
    this.min,
    this.max,
    this.value,
    this.step,
    this.onChanged
  });

  @override
  Widget build(BuildContext context) {
    if (value == null) {
      return SizedBox();
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10),
      child: FlutterSlider(
        values: [value],
        max: max,
        min: min,
        step: FlutterSliderStep(
            step: step
        ),
        onDragCompleted: (handlerIndex, lowerValue, upperValue) => onChanged(lowerValue),
        handler: FlutterSliderHandler(
          decoration: BoxDecoration(
            boxShadow: [const BoxShadow(color: Colors.black26, blurRadius: 2, spreadRadius: 0.2, offset: Offset(0, 1))],
            color: Colors.white,
            shape: BoxShape.circle
          ),
          child: Container()
        ),
      )
    );
  }
}