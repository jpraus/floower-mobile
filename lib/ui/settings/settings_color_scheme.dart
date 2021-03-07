import 'dart:async';

import 'package:Floower/logic/floower_connector.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:reorderables/reorderables.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:dashed_container/dashed_container.dart';
import 'package:flutter_xlider/flutter_xlider.dart';

import 'package:Floower/logic/floower_color.dart';
import 'package:Floower/logic/floower_model.dart';
import 'package:Floower/ui/cupertino_list.dart';
import 'package:tinycolor/conversion.dart';
import 'package:tinycolor/tinycolor.dart';

import '../commons.dart';

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

  void _onColorTap(BuildContext context, FloowerColor color, int index) {
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
      widget.floowerModel.setColor(color);
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
      widget.floowerModel.setColor(FloowerColor.COLOR_RED);
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

  void _onResetScheme(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (context) => new CupertinoAlertDialog(
        title: Text("Reset Color Scheme"),
        content: Text("Do you want to reset your Floower's color scheme to the standard one?"),
        actions: <Widget>[
          new CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: new Text("No")),
          new CupertinoDialogAction(
            onPressed: () {
              _resetScheme();
              Navigator.of(context).pop(); // close
            },
            child: new Text("Yes"))
        ],
      ),
    );
  }

  void _resetScheme() async {
    setState(() {
      _colorScheme = []..addAll(FloowerColor.DEFAULT_SCHEME);
      _removing = false;
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
          onTap: () => _onColorTap(context, color, i),
          onLongPress: _onColorLongPress,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.displayColor,
              border: Border.all(color: borderColor.withOpacity(color.isLight() ? 0.1 : 0)),
            ),
            child: _removing ? Icon(CupertinoIcons.clear_thick, size: 20, color: color.isLight() ? Colors.black : Colors.white) : null
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
            child: Icon(CupertinoIcons.check_mark, color: CupertinoColors.white),
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
              child: Icon(CupertinoIcons.add),
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
      heading: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: Text("Color Scheme")
          ),
          GestureDetector(
            onTap: () => _onResetScheme(context),
            child: Icon(CupertinoIcons.restart, size: 20, color: FloowerTextTheme.secondaryColor())
          ),
        ],
      ),


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

  HslColor _currentHslColor = FloowerColor.COLOR_RED.displayHSLColor;

  @override
  void initState() {
    super.initState();
    if (widget.originalColor != null) {
      _currentHslColor = widget.originalColor.displayHSLColor;
    }
  }

  @override
  void didUpdateWidget(_ColorPickerDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.originalColor != null) {
      _currentHslColor = widget.originalColor.displayHSLColor;
    }
  }

  Future<bool> _onWillPop() async {
    _showColor(Colors.black);
    return true;
  }

  void _onSave(BuildContext context) async {
    _showColor(Colors.black);
    widget.colorPicked(FloowerColor.fromDisplayColor(hslToRgb(_currentHslColor)));
    Navigator.pop(context);
  }

  void _onCancel(BuildContext context) async {
    _showColor(Colors.black);
    Navigator.pop(context);
  }

  void _onChangeColor(HslColor color) {
    setState(() => _currentHslColor = color);
    _showColor(hslToRgb(_currentHslColor));
  }

  Future<void> _showColor(Color color) async {
    widget.floowerModel.setColor(FloowerColor.fromDisplayColor(color), transitionDuration: Duration(milliseconds: 500), notifyListener: false);
  }

  @override
  Widget build(BuildContext context) {
    TinyColor currentColor = TinyColor.fromHSL(_currentHslColor);

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
                  ),
                  SliverList(
                    delegate: SliverChildListDelegate([
                      Container(
                        padding: EdgeInsets.only(left: 15, top: 25, bottom: 10),
                        child: Text("Hue"),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: FlutterSlider(
                          values: [_currentHslColor.h],
                          max: 360.0,
                          min: 0,
                          onDragging: (handlerIndex, lowerValue, upperValue) {
                            _onChangeColor(HslColor(h: lowerValue, l: _currentHslColor.l, s: 1.0, a: 255.0));
                          },
                          handler: FlutterSliderHandler(
                            decoration: BoxDecoration(
                              boxShadow: [const BoxShadow(color: Colors.black26, blurRadius: 2, spreadRadius: 0.2, offset: Offset(0, 1))],
                              color: HSVColor.fromAHSV(1.0, _currentHslColor.h, 1.0, 1.0).toColor(),
                              shape: BoxShape.circle
                            ),
                            child: Container()
                          ),
                          handlerAnimation: FlutterSliderHandlerAnimation(
                            curve: Curves.elasticOut,
                            reverseCurve: Curves.bounceIn,
                            duration: Duration(milliseconds: 500),
                            scale: 1.5
                          ),
                          trackBar: FlutterSliderTrackBar(
                            inactiveTrackBar: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              color: Colors.white, // opacity 1
                              gradient: LinearGradient(
                                colors: [
                                  const HSVColor.fromAHSV(1.0, 0.0, 1.0, 1.0).toColor(),
                                  const HSVColor.fromAHSV(1.0, 60.0, 1.0, 1.0).toColor(),
                                  const HSVColor.fromAHSV(1.0, 120.0, 1.0, 1.0).toColor(),
                                  const HSVColor.fromAHSV(1.0, 180.0, 1.0, 1.0).toColor(),
                                  const HSVColor.fromAHSV(1.0, 240.0, 1.0, 1.0).toColor(),
                                  const HSVColor.fromAHSV(1.0, 300.0, 1.0, 1.0).toColor(),
                                  const HSVColor.fromAHSV(1.0, 360.0, 1.0, 1.0).toColor()
                                ]
                              )
                            ),
                            activeTrackBarHeight: 10,
                            inactiveTrackBarHeight: 10,
                            activeTrackBar: BoxDecoration(
                              color: Colors.transparent,
                            )
                          ),
                        )
                      ),
                      Container(
                        padding: EdgeInsets.only(left: 15, top: 25, bottom: 10),
                        child: Text("Lightness"),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: FlutterSlider(
                          values: [_currentHslColor.l],
                          max: 1.0,
                          min: 0,
                          step: FlutterSliderStep(
                            step: 0.01
                          ),
                          onDragging: (handlerIndex, lowerValue, upperValue) {
                            _onChangeColor(HslColor(h: _currentHslColor.h, l: lowerValue, s: 1.0, a: 255.0));
                          },
                          handler: FlutterSliderHandler(
                            decoration: BoxDecoration(
                              boxShadow: [const BoxShadow(color: Colors.black26, blurRadius: 2, spreadRadius: 0.2, offset: Offset(0, 1))],
                              color: currentColor.color,
                              shape: BoxShape.circle
                            ),
                            child: Container()
                          ),
                          handlerAnimation: FlutterSliderHandlerAnimation(
                            curve: Curves.elasticOut,
                            reverseCurve: Curves.bounceIn,
                            duration: Duration(milliseconds: 500),
                            scale: 1.5
                          ),
                          trackBar: FlutterSliderTrackBar(
                            inactiveTrackBar: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              color: Colors.white, // opacity 1
                              gradient: LinearGradient(
                                colors: [
                                  HSLColor.fromAHSL(1.0, _currentHslColor.h, 1.0, 0.0).toColor(),
                                  HSLColor.fromAHSL(1.0, _currentHslColor.h, 1.0, 0.5).toColor(),
                                  HSLColor.fromAHSL(1.0, _currentHslColor.h, 1.0, 1.0).toColor(),
                                ]
                              )
                            ),
                            activeTrackBarHeight: 10,
                            inactiveTrackBarHeight: 10,
                            activeTrackBar: BoxDecoration(
                              color: Colors.transparent,
                            )
                          ),
                        )
                      ),
                      Container(
                        padding: EdgeInsets.only(left: 15, right: 15, top: 30),
                        child: CupertinoButton(
                          child: Text("Use Color", style: TextStyle(color: currentColor.isLight() ? Colors.black : Colors.white)),
                          color: currentColor.color,
                          onPressed: () => _onSave(context)
                        ),
                      ),
                    ]),
                  )
                ],
              );
            }
        ),
      ),
    );
  }
}