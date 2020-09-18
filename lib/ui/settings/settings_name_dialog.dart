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

class SettingNameDialog extends StatefulWidget {
  @override
  _SettingNameDialogState createState() => _SettingNameDialogState();
}

class _SettingNameDialogState extends State<SettingNameDialog> {

  final _nameTextController = TextEditingController();
  bool _textSet = false;
  bool _valid = false;

  @override
  void dispose() {
    _nameTextController.dispose();
    super.dispose();
  }

  void _onSave(BuildContext context) {
    String name = _nameTextController.text;
    if (!name.isEmpty) {
      FloowerModel floowerModel = Provider.of<FloowerModel>(context, listen: false);
      floowerModel.setName(name);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_textSet) {
      FloowerModel floowerModel = Provider.of<FloowerModel>(context, listen: false);
      _nameTextController.text = floowerModel.name;
      _textSet = true;
      if (!floowerModel.name.isEmpty) {
        _valid = true;
      }
    }

    return Scaffold(
      backgroundColor: CupertinoTheme.of(context).barBackgroundColor,
      body: CustomScrollView(
        slivers: <Widget>[
          new CupertinoSliverNavigationBar(
            largeTitle: const Text("Floower Name"),
            automaticallyImplyLeading: false,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Icon(CupertinoIcons.clear_thick, color: CupertinoColors.label),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              SizedBox(height: 18),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 18),
                child: Text("Give your Floower a unique name to distinguish it from others. The name will be changed after the Floower is restarted.",
                    style: TextStyle(fontSize: 20, color: CupertinoColors.inactiveGray)),
              ),
              SizedBox(height: 18),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 18),
                child: CupertinoTextField(
                  maxLength: FloowerConnector.MAX_NAME_LENGTH,
                  maxLengthEnforced: true,
                  maxLines: 1,
                  padding: EdgeInsets.all(18),
                  placeholder: "Your's Floower Name",
                  autofocus: true,
                  controller: _nameTextController,
                  onChanged: (value) {
                    setState(() {
                      _valid = !value.isEmpty;
                    });
                  },
                ),
              ),
              SizedBox(height: 18),
            ]),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(CupertinoIcons.right_chevron),
        backgroundColor: _valid ? CupertinoColors.activeBlue : CupertinoColors.inactiveGray,
        onPressed: _valid ? () => _onSave(context) : null,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}