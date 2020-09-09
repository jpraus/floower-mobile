import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:meta/meta.dart';
import 'package:provider/provider.dart';
import 'package:system_setting/system_setting.dart';

import 'package:Floower/logic/floower_model.dart';
import 'package:Floower/logic/floower_connector.dart';
import 'package:Floower/ui/connect_route.dart';
import 'package:Floower/ui/cupertino_list.dart';

class SettingsRoute extends StatelessWidget {
  static const ROUTE_NAME = '/settings';

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.extraLightBackgroundGray,
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

  @override
  Widget build(BuildContext context) {
    return Consumer<FloowerModel>(
      builder: (_, floowerModel, __) => ListView(
        children: _buildSettingsContent(context, floowerModel),
      ),
    );
  }

  void _onDisconnect(BuildContext context) {
    print("Disconnect");
    Navigator.pushNamed(context, ConnectRoute.ROUTE_NAME);
  }

  List<Widget> _buildSettingsContent(BuildContext context, FloowerModel floowerModel) {
    bool deviceConnected = false;
    List<Widget> column = [];

    // connected devices
    column.add(const SizedBox(height: 35));
    column.add(CupertinoList(
      children: [
        CupertinoListItem(
          title: Text("Floower Connected"),
          trailing: GestureDetector(
            child: Text("DISCONNECT", style: CupertinoTheme.of(context).textTheme.actionTextStyle),
            onTap: () => _onDisconnect(context),
          ),
        ),
        CupertinoListItem(
          title: Text("Name"),
          trailing: Row(
            children: [
              Text("Floower", style: TextStyle(color: CupertinoColors.tertiaryLabel)),
              Icon(CupertinoIcons.forward, color: CupertinoColors.tertiaryLabel),
            ],
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

    column.add(CupertinoList(
      margin: EdgeInsets.only(top: 35),
      heading: Text("Color Scheme"),
      children: [
        CupertinoListItem(
          title: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                margin: EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.all(Radius.circular(3.0))
                ),
              ),
              Text("Red")
            ],
          ),
        ),
        CupertinoListItem(
          title: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                margin: EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                    color: Colors.yellow,
                    borderRadius: BorderRadius.all(Radius.circular(3.0))
                ),
              ),
              Text("Yellow")
            ],
          ),
        ),
      ],
    ));

    column.add(CupertinoList(
      margin: EdgeInsets.only(top: 35),
      heading: Text("About"),
      children: [
        CupertinoListItem(
          title: Text("Serial Number"),
          trailing: Text("0015", style: TextStyle(color: CupertinoColors.tertiaryLabel)),
        ),
        CupertinoListItem(
          title: Text("Model"),
          trailing: Text("Floower", style: TextStyle(color: CupertinoColors.tertiaryLabel)),
        ),
        CupertinoListItem(
          title: Text("Firmware Version"),
          trailing: Text("1.0", style: TextStyle(color: CupertinoColors.tertiaryLabel)),
        ),
        CupertinoListItem(
          title: Text("Hardware Version"),
          trailing: Text("1.0", style: TextStyle(color: CupertinoColors.tertiaryLabel)),
        ),
      ],
    ));

    return column;
  }
}