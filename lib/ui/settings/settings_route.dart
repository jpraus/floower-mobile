import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

import 'package:Floower/logic/floower_model.dart';
import 'package:Floower/logic/floower_connector.dart';
import 'package:Floower/ui/home_route.dart';
import 'package:Floower/ui/cupertino_list.dart';
import 'package:Floower/ui/settings/settings_name_dialog.dart';
import 'package:Floower/ui/settings/settings_color_scheme.dart';

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
    await Provider.of<FloowerConnector>(context, listen: false).disconnect();
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
            onTap: () => _onDisconnect(context),
          ),
        ),
        CupertinoListItem(
          title: Text("Name"),
          trailing: GestureDetector(
            onTap: () => _onNameTap(context),
            child: Row(
              children: [
                Text(floowerModel.name, style: TextStyle(color: CupertinoColors.tertiaryLabel)),
                Icon(CupertinoIcons.forward, color: CupertinoColors.tertiaryLabel),
              ],
            ),
          ),
        ),
        CupertinoListItem(
          title: Text("Behavior"),
          trailing: Row(
            children: [
              Text("Blooming Flower", style: TextStyle(color: CupertinoColors.tertiaryLabel)),
              Icon(CupertinoIcons.forward, color: CupertinoColors.tertiaryLabel),
            ],
          ),
        ),
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
          trailing: Text(floowerModel.serialNumber?.toString()?.padLeft(4, '0') ?? "", style: TextStyle(color: CupertinoColors.tertiaryLabel)),
        ),
        CupertinoListItem(
          title: Text("Model"),
          trailing: Text(floowerModel.modelName ?? "", style: TextStyle(color: CupertinoColors.tertiaryLabel)),
        ),
        CupertinoListItem(
          title: Text("Firmware Version"),
          trailing: Text(floowerModel.firmwareVersion?.toString() ?? "", style: TextStyle(color: CupertinoColors.tertiaryLabel)),
        ),
        CupertinoListItem(
          title: Text("Hardware Version"),
          trailing: Text(floowerModel.hardwareRevision?.toString() ?? "", style: TextStyle(color: CupertinoColors.tertiaryLabel)),
        ),
      ],
    ));

    return ListView(
      children: column,
    );
  }
}