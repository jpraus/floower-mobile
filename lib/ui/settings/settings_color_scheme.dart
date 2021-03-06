import 'dart:async';

import 'package:Floower/logic/floower_connector.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:reorderables/reorderables.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:dashed_container/dashed_container.dart';

import 'package:Floower/logic/floower_color.dart';
import 'package:Floower/logic/floower_model.dart';
import 'package:Floower/ui/cupertino_list.dart';
import 'package:tinycolor/tinycolor.dart';

class ColorSchemePicker extends StatefulWidget {
  FloowerModel floowerModel;

  ColorSchemePicker({
    Key key,
    @required this.floowerModel
  }) : super(key: key);

  @override
  ColorSchemePickerState createState() => ColorSchemePickerState();
}

class ColorSchemePickerState extends State<ColorSchemePicker> {

  List<FloowerColor> _colorScheme;
  bool _removing = false;

  @override
  void initState() {
    super.initState();
    widget.floowerModel.getColorsScheme().then((colorScheme) {
      setState(() {
        _colorScheme = colorScheme;
      });
    });
  }

  void _onColorTap(FloowerColor color, int index) {
    if (_removing) {
      setState(() {
        _colorScheme.removeAt(index);
        if (_colorScheme.length == 1) {
          _removing = false; // dot allow to remove last color
        }
      });
      // upload to Floower
      widget.floowerModel.setColorScheme(_colorScheme);
    }
    else {
      showCupertinoModalBottomSheet(
        expand: true,
        context: context,
        builder: (context) => _ColorPickerDialog(
          floowerModel: widget.floowerModel,
          originalColor: color,
          colorPicked: (color) {
            setState(() {
              _colorScheme.removeAt(index);
              _colorScheme.insert(index, color);
            });
            // upload to Floower
            widget.floowerModel.setColorScheme(_colorScheme);
          }
        )
      );
    }
  }

  void _onColorAdd() {
    if (_colorScheme.length < FloowerConnector.MAX_SCHEME_COLORS) {
      showCupertinoModalBottomSheet(
        expand: true,
        context: context,
        builder: (context) => _ColorPickerDialog(
          floowerModel: widget.floowerModel,
          colorPicked: (color) {
            setState(() {
              _colorScheme.add(color);
            });
            // upload to Floower
            widget.floowerModel.setColorScheme(_colorScheme);
          }
        )
      );
    }
  }

  void _onColorLongPress() {
    if (_colorScheme.length > 1) {
      setState(() {
        _removing = true;
      });
    }
  }

  void _onRemovingDone() {
    setState(() {
      _removing = false;
    });
  }

  void _onColorReorder(oldIndex, newIndex) {
    if (newIndex == _colorScheme.length) {
      newIndex--; // moving beyond the + button
    }
    setState(() {
      FloowerColor color = _colorScheme.removeAt(oldIndex);
      _colorScheme.insert(newIndex, color);
    });
    // upload to Floower
    widget.floowerModel.setColorScheme(_colorScheme);
  }

  @override
  Widget build(BuildContext context) {
    if (_colorScheme == null) {
      return SizedBox(width: 0, height: 0);
    }

    Color borderColor = WidgetsBinding.instance.window.platformBrightness == Brightness.dark ? Colors.white : Colors.black;
    List<Widget> items = [];

    for (int i = 0; i < _colorScheme.length; i++) {
      FloowerColor color = _colorScheme[i];
      items.add(ReorderableWidget(
        reorderable: true,
        key: ObjectKey(color),
        child: GestureDetector(
          onTap: () => _onColorTap(color, i),
          onLongPress: _onColorLongPress,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.displayColor,
              border: Border.all(color: borderColor.withOpacity(color.isLight() ? 0.1 : 0)),
            ),
            child: _removing ? Icon(CupertinoIcons.clear_thick, color: color.isLight() ? Colors.black : Colors.white) : null
          ),
        ),
      ));
    }

    if (_removing) {
      items.add(ReorderableWidget(
        reorderable: false,
        key: UniqueKey(),
        child: GestureDetector(
          onTap: _onRemovingDone,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: CupertinoColors.activeBlue
            ),
            child: Icon(CupertinoIcons.check_mark, size: 40, color: CupertinoColors.white),
          ),
        ),
      ));
    }
    else if (_colorScheme.length < FloowerConnector.MAX_SCHEME_COLORS) {
      items.add(ReorderableWidget(
        reorderable: false,
        key: UniqueKey(),
        child: GestureDetector(
          onTap: _removing ? _onRemovingDone : _onColorAdd,
          child: DashedContainer(
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle
              ),
              child: Icon(CupertinoIcons.add, size: 40),
            ),
            dashColor: borderColor.withOpacity(0.2),
            boxShape: BoxShape.circle,
            dashedLength: 5.0,
            blankLength: 5.0,
            strokeWidth: 1.0,
          ),
        ),
      ));
    }

    return CupertinoList(
      margin: EdgeInsets.only(top: 35),
      heading: Text("Color Scheme"),
      children: [Container(
        width: double.infinity,
        padding: EdgeInsets.all(18),
        color: CupertinoTheme.of(context).barBackgroundColor,
        child: ReorderableWrap(
          children: items,
          spacing: 16,
          runSpacing: 16,
          needsLongPressDraggable: false,
          buildDraggableFeedback: (context, BoxConstraints constraints, Widget child) {
            return Transform(
              transform: new Matrix4.rotationZ(0),
              alignment: FractionalOffset.topLeft,
              child: Material(
                child: ConstrainedBox(constraints: constraints, child: child),
                type: MaterialType.circle,
                elevation: 6.0,
                color: Colors.transparent
              ),
            );
          },
          onReorder: _onColorReorder,
        ),
      )],
    );
  }
}

class _ColorPickerDialog extends StatefulWidget {

  final FloowerColor originalColor;
  final Function(FloowerColor color) colorPicked;
  final FloowerModel floowerModel;

  _ColorPickerDialog({ this.originalColor, @required this.colorPicked, this.floowerModel });

  @override
  _ColorPickerDialogState createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {

  HSVColor currentHsvColor = hslToHsv(HSLColor.fromAHSL(1, 180, 1, 0.5));

  @override
  void initState() {
    super.initState();
    if (widget.originalColor != null) {
      currentHsvColor = HSVColor.fromColor(widget.originalColor.displayColor);
      _showColor(currentHsvColor.toColor());
    }
  }

  @override
  void didUpdateWidget(_ColorPickerDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.originalColor != null) {
      currentHsvColor = HSVColor.fromColor(widget.originalColor.displayColor);
    }
  }

  Future<bool> _onWillPop() async {
    _showColor(Colors.black);
    return true;
  }

  void _onSave(BuildContext context) async {
    _showColor(Colors.black);
    widget.colorPicked(FloowerColor.fromDisplayColor(currentHsvColor.toColor()));
    Navigator.pop(context);
  }

  void _onCancel(BuildContext context) async {
    _showColor(Colors.black);
    Navigator.pop(context);
  }

  void _onChangeColor(HSVColor color) {
    color = hslToHsv(hsvToHsl(color).withSaturation(1));
    setState(() => currentHsvColor = color);
    _showColor(color.toColor());
  }

  void _showColor(Color color) {
    widget.floowerModel.setColor(FloowerColor.fromDisplayColor(color));
  }

  @override
  Widget build(BuildContext context) {
    TinyColor currentColor = TinyColor.fromHSV(currentHsvColor);

    Color borderColor = WidgetsBinding.instance.window.platformBrightness == Brightness.dark ? Colors.white : Colors.black;
    List<Widget> defaultColors = [];

    for (FloowerColor color in FloowerColor.DEFAULT_SCHEME) {
      defaultColors.add(GestureDetector(
        onTap: () => _onChangeColor(color.displayHSVColor),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.displayColor,
            border: Border.all(color: borderColor.withOpacity(color.isLight() ? 0.1 : 0)),
          ),
        ),
      ));
    }

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: CupertinoTheme.of(context).barBackgroundColor,
        body: LayoutBuilder(
          builder: (context, constraints) {
            return CustomScrollView(
              slivers: <Widget>[
                new CupertinoSliverNavigationBar(
                  largeTitle: Text(widget.originalColor == null ? "Add New Color" : "Edit Color"),
                  leading: GestureDetector(
                    onTap: () => _onCancel(context),
                    child: Icon(CupertinoIcons.clear_thick, color: CupertinoTheme.of(context).textTheme.textStyle.color),
                  ),
                  /*trailing: GestureDetector(
                    onTap: () => _onSave(context),
                    child: Icon(CupertinoIcons.check_mark_circled_solid),
                  ),*/
                ),
                SliverList(
                  delegate: SliverChildListDelegate([
                    Container(
                        padding: EdgeInsets.symmetric(horizontal: 25, vertical: 40),
                        child: Wrap(
                          children: defaultColors,
                          spacing: 16,
                          runSpacing: 16,
                        )
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      height: 100,
                      child: ColorPickerSlider(
                        TrackType.hue,
                        currentHsvColor,
                        _onChangeColor,
                        displayThumbColor: true,
                      )
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      height: 100,
                      child: ColorPickerSlider(
                        TrackType.lightness,
                        currentHsvColor,
                        _onChangeColor,
                        displayThumbColor: true,
                      )
                    ),
                  ]),
                )
              ],
            );
          }
        ),
        floatingActionButton: FloatingActionButton(
          child: Icon(CupertinoIcons.right_chevron, color: currentColor.isLight() ? Colors.black : Colors.white),
          backgroundColor: currentHsvColor.toColor(),
          onPressed: () => _onSave(context),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }
}