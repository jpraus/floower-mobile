import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reorderables/reorderables.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

import 'package:Floower/logic/floower_model.dart';
import 'package:Floower/logic/floower_connector.dart';
import 'package:Floower/ui/home_route.dart';
import 'package:Floower/ui/cupertino_list.dart';
import 'package:Floower/ui/settings/settings_name_dialog.dart';

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
      backgroundColor: Colors.white,
      builder: (context, scrollController) => SettingNameDialog()
    );
/*
    Navigator.push(context, CupertinoPageRoute(
      builder: (context) => SafeArea(
        child: Container(color: Colors.red),
      ),
      title: "Title",
      fullscreenDialog: true
    ));

    showCupertinoDialog(
      context: context,
      builder: (context) {
        return SafeArea(
          child: CupertinoPopupSurface(
            child: CupertinoTextField(
            ),
          ),
        );
      }
    );*/
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
          title: Text("Floower Connected"),
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
    column.add(_ColorSchemePicker(
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

class _ColorSchemePicker extends StatefulWidget {
  FloowerModel floowerModel;

  _ColorSchemePicker({
    Key key,
    @required this.floowerModel
  }) : super(key: key);

  @override
  _ColorSchemePickerState createState() => _ColorSchemePickerState();
}

class _ColorSchemePickerState extends State<_ColorSchemePicker> {

  List<FloowerColor> _colorScheme;

  @override
  void initState() {
    super.initState();
    widget.floowerModel.getColorsScheme().then((colorScheme) {
      setState(() {
        _colorScheme = colorScheme;
      });
    });
  }

  void _onColorTap() {

  }

  void _onColorLongPress() {

  }

  void _onColorReorder(oldIndex, newIndex) {
    FloowerColor color = _colorScheme.removeAt(oldIndex);
    _colorScheme.insert(newIndex, color);
    widget.floowerModel.setColorScheme(_colorScheme);
  }

  @override
  Widget build(BuildContext context) {
    if (_colorScheme == null) {
      return SizedBox(width: 0, height: 0);
    }

    Color borderColor = CupertinoTheme.of(context).brightness == Brightness.light ? Colors.black : Colors.white;
    List<Widget> items = _colorScheme.map((color) => GestureDetector(
      onLongPress: _onColorTap,
      onTap: _onColorLongPress,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.displayColor,
            border: Border.all(color: borderColor.withOpacity(color.isLight() ? 0.4 : 0.2))
        ),
      ),
    )).toList();

    return CupertinoList(
      margin: EdgeInsets.only(top: 35),
      heading: Text("Color Scheme"),
      children: [Container(
        width: double.infinity,
        padding: EdgeInsets.all(18),
        color: Colors.white,
        child: ReorderableWrap(
          children: items,
          spacing: 16,
          runSpacing: 16,
          needsLongPressDraggable: false,
          onReorder: _onColorReorder,
        ),
      )],
    );
  }
}

