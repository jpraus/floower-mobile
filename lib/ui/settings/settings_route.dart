import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

import 'package:Floower/logic/floower_model.dart';
import 'package:Floower/logic/floower_connector_ble.dart';
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
      backgroundColor: CupertinoTheme.of(context).barBackgroundColor,
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
    await Provider.of<FloowerConnectorBle>(context, listen: false).disconnect();
    await Provider.of<FloowerConnectorBle>(context, listen: false).disconnect();
    Navigator.popUntil(context, ModalRoute.withName(HomeRoute.ROUTE_NAME));
  }

  void _onNameTap(BuildContext context) {
    showCupertinoModalBottomSheet(
      expand: true,
      context: context,
      builder: (context, scrollController) => SettingNameDialog()
    );
  }

  @override
  Widget build(BuildContext context) {
    FloowerModel floowerModel = Provider.of<FloowerModel>(context);
    bool deviceConnected = false;
    List<Widget> column = [];

    // connected devices
    column.add(const SizedBox(height: 35));
    column.add(CupertinoList(
      children: [
        CupertinoListItem(
          title: Text("Connected"),
          trailing: GestureDetector(
            child: Text("DISCONNECT", style: CupertinoTheme.of(context).textTheme.actionTextStyle),
            onTap: () {
              floowerModel.disconnect();
              Navigator.popUntil(context, ModalRoute.withName(HomeRoute.ROUTE_NAME));
            },
          ),
        ),
        CupertinoListItem(
          title: Text("Name"),
          onTap: () => _onNameTap(context),
          trailing: Row(
            children: [
              Text(floowerModel.name, style: const TextStyle(color: CupertinoColors.tertiaryLabel)),
              const Icon(CupertinoIcons.forward, color: CupertinoColors.tertiaryLabel),
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
        CupertinoListItem(
          title: Text("Touch Sensitivity"),
        ),
        CupertinoListItem(
          leading: const Text("Low", style: TextStyle(color: CupertinoColors.tertiaryLabel)),
          title: TouchSensitivitySlider(
            floowerModel: floowerModel,
          ),
          trailing: const Text("High", style: TextStyle(color: CupertinoColors.tertiaryLabel)),
        )
      ],
    ));

    // color scheme section
    column.add(ColorSchemePicker(
      floowerModel: floowerModel,
    ));

    // about sections
    column.add(CupertinoList(
      margin: EdgeInsets.only(top: 35),
      heading: Text("About"),
      children: [
        CupertinoListItem(
          title: Text("Serial Number"),
          trailing: Text(floowerModel.serialNumber?.toString()?.padLeft(4, '0') ?? "", style: const TextStyle(color: CupertinoColors.tertiaryLabel)),
        ),
        CupertinoListItem(
          title: Text("Model"),
          trailing: Text(floowerModel.modelName ?? "", style: const TextStyle(color: CupertinoColors.tertiaryLabel)),
        ),
        CupertinoListItem(
          title: Text("Firmware Version"),
          trailing: Text(floowerModel.firmwareVersion?.toString() ?? "", style: const TextStyle(color: CupertinoColors.tertiaryLabel)),
        ),
        CupertinoListItem(
          title: Text("Hardware Version"),
          trailing: Text(floowerModel.hardwareRevision?.toString() ?? "", style: const TextStyle(color: CupertinoColors.tertiaryLabel)),
        ),
        CupertinoListItem(
          title: Text("App Version"),
          trailing: FutureBuilder(
            future: PackageInfo.fromPlatform(),
            builder: (BuildContext context, AsyncSnapshot<PackageInfo> snapshot) {
              return Text(snapshot.hasData ? snapshot.data.version : "?", style: const TextStyle(color: CupertinoColors.tertiaryLabel));
            },
          )
        ),
      ],
    ));

    return ListView(
      children: column,
    );
  }
}

class TouchSensitivitySlider extends StatefulWidget {

  final FloowerModel floowerModel;

  TouchSensitivitySlider({ @required this.floowerModel });

  @override
  _TouchSensitivitySliderState createState() => _TouchSensitivitySliderState();
}

class _TouchSensitivitySliderState extends State<TouchSensitivitySlider> {

  double _value;

  @override
  void initState() {
    _value = widget.floowerModel.touchThreshold?.toDouble();
    super.initState();
  }

  void _onChanged(double value) {
    setState(() {
      _value = value;
    });
    widget.floowerModel.setTouchThreshold(value.toInt());
  }

  @override
  Widget build(BuildContext context) {
    if (_value == null) {
      return SizedBox();
    }

    return CupertinoSlider(
      value: _value,
      onChanged: _onChanged,
      min: 35,
      max: 55,
      divisions: 20,
    );
  }
}