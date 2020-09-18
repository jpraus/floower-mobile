import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reorderables/reorderables.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

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
    showCupertinoModalBottomSheet(
      expand: true,
      context: context,
      builder: (context, scrollController) => _ColorPickerDialog(
        originalColor: color,
        colorPicked: (color) {
          setState(() {
            _colorScheme.removeAt(index);
            _colorScheme.insert(index, color);
          });
          // TODO: persist
        }
      )
    );
  }

  void _onColorAdd() {
    showCupertinoModalBottomSheet(
      expand: true,
      context: context,
      builder: (context, scrollController) => _ColorPickerDialog(
        colorPicked: (color) {
          setState(() {
            _colorScheme.add(color);
          });
          // TODO: persist
        }
      )
    );
  }

  void _onColorLongPress() {
    setState(() {
      _removing = true;
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
    //widget.floowerModel.setColorScheme(_colorScheme);
  }

  @override
  Widget build(BuildContext context) {
    if (_colorScheme == null) {
      return SizedBox(width: 0, height: 0);
    }

    Color borderColor = CupertinoTheme.of(context).brightness == Brightness.light ? Colors.black : Colors.white;
    List<Widget> items = [];

    for (int i = 0; i < _colorScheme.length; i++) {
      FloowerColor color = _colorScheme[i];
      items.add(ReorderableWidget(
        reorderable: true,
        key: ObjectKey(color),
        child: GestureDetector(
          onLongPress: () => _onColorTap(color, i),
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
        ),
      ));
    }

    items.add(ReorderableWidget(
      reorderable: false,
      key: UniqueKey(),
      child: GestureDetector(
        onLongPress: _onColorAdd,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: CupertinoTheme.of(context).brightness == Brightness.light ? Colors.white : Colors.black,
            border: Border.all(color: borderColor.withOpacity(0.2))
          ),
          child: Icon(CupertinoIcons.add),
        ),
      ),
    ));

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
          buildDraggableFeedback: (context, BoxConstraints constraints, Widget child) {
            print("feeback");
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

  FloowerColor originalColor;
  Function(FloowerColor color) colorPicked;

  _ColorPickerDialog({ this.originalColor, @required this.colorPicked });

  @override
  _ColorPickerDialogState createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {

  HSVColor currentHsvColor = const HSVColor.fromAHSV(0.0, 0.0, 0.0, 0.0);

  @override
  void initState() {
    super.initState();
    currentHsvColor = HSVColor.fromColor(widget.originalColor.displayColor);
  }

  @override
  void didUpdateWidget(_ColorPickerDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    currentHsvColor = HSVColor.fromColor(widget.originalColor.displayColor);
  }

  @override
  void dispose() {



    FloowerModel floowerModel = Provider.of<FloowerModel>(context, listen: false);
    floowerModel.setColor(FloowerColor.black);
    super.dispose();
  }

  void _onSave(BuildContext context) async {
    FloowerColor color = FloowerColor.fromHwColor(currentHsvColor.toColor());
    widget.colorPicked(color);
    Navigator.pop(context);
  }

  void _onChangeColor(HSVColor color) {
    HSLColor hslColor = HSLColor.fromColor(color.toColor());
    hslColor = hslColor.withSaturation(1);

    setState(() => currentHsvColor = HSVColor.fromColor(hslColor.toColor()));
    FloowerModel floowerModel = Provider.of<FloowerModel>(context, listen: false);
    floowerModel.setColor(FloowerColor.fromDisplayColor(currentHsvColor.toColor()));
  }

  @override
  Widget build(BuildContext context) {
    TinyColor color = TinyColor.fromHSV(currentHsvColor);
    HSVColor modifiedColor = HSVColor.fromAHSV(1, currentHsvColor.hue, 1, 1);
    FloowerColor currentColor = FloowerColor.fromDisplayColor(currentHsvColor.toColor());

    return Scaffold(
      backgroundColor: CupertinoTheme.of(context).barBackgroundColor,
      body: LayoutBuilder(
        builder: (context, constraints) {
          double refHeight = constraints.maxHeight;
          return CustomScrollView(
            slivers: <Widget>[
              new CupertinoSliverNavigationBar(
                largeTitle: const Text("Pick a Color"),
                automaticallyImplyLeading: false,
                leading: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(CupertinoIcons.clear_thick, color: CupertinoColors.label),
                ),
              ),
              SliverList(
                delegate: SliverChildListDelegate([
                  Container(
                    //padding: EdgeInsets.all(18),
                    width: constraints.maxWidth,
                    height: constraints.maxHeight / 2,
                    child: ColorPickerArea(
                      currentHsvColor,
                      _onChangeColor,
                      PaletteType.hsl
                    ),
                  ),
                  SizedBox(height: 36),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    height: 80,
                    child: ColorPickerSlider(
                      TrackType.hue,
                      currentHsvColor,
                      _onChangeColor,
                      displayThumbColor: true,
                    )
                  ),
                  Container(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      height: 80,
                      child: ColorPickerSlider(
                        TrackType.lightness,
                        currentHsvColor,
                        _onChangeColor,
                        displayThumbColor: true,
                      )
                  ),
                  SizedBox(height: 18),
                ]),
              )
            ],
          );
        }
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(CupertinoIcons.right_chevron, color: currentColor.isLight() ? Colors.black : Colors.white),
        backgroundColor: currentColor.displayColor,
        onPressed: () => _onSave(context),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}