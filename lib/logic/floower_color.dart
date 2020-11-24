import 'package:flutter/material.dart';
import 'package:tinycolor/tinycolor.dart';

class FloowerColor {

  static const int INTENSITY_SHIFT = 30;

  // pre-defined colors, keep in sync with firmware
  static FloowerColor COLOR_RED = FloowerColor.fromHwRGB(156, 0, 0);
  static FloowerColor COLOR_GREEN = FloowerColor.fromHwRGB(40, 178, 0);
  static FloowerColor COLOR_BLUE = FloowerColor.fromHwRGB(0, 65, 178);
  static FloowerColor COLOR_YELLOW = FloowerColor.fromHwRGB(178, 170, 0);
  static FloowerColor COLOR_ORANGE = FloowerColor.fromHwRGB(178, 64, 0);
  static FloowerColor COLOR_WHITE = FloowerColor.fromHwRGB(178, 178, 178);
  static FloowerColor COLOR_PURPLE = FloowerColor.fromHwRGB(148, 0, 178);
  static FloowerColor COLOR_PINK = FloowerColor.fromHwRGB(178, 0, 73);

  static List<FloowerColor> DEFAULT_SCHEME = [
    COLOR_WHITE,
    COLOR_YELLOW,
    COLOR_ORANGE,
    COLOR_RED,
    COLOR_PINK,
    COLOR_PURPLE,
    COLOR_BLUE,
    COLOR_GREEN,
  ];

  final TinyColor _displayColor;

  FloowerColor._(this._displayColor);

  Color get displayColor => _displayColor.color;
  HSVColor get displayHSVColor => _displayColor.toHsv();
  Color get hwColor => _displayColor.brighten(-INTENSITY_SHIFT).color; // intensity down by 30% so it's nice on the display

  bool isBlack() {
    return _displayColor.getBrightness() == 0;
  }

  bool isLight() {
    return _displayColor.isLight();
  }

  static FloowerColor black = FloowerColor.fromDisplayColor(Colors.black);

  static FloowerColor fromDisplayColor(Color displayColor) {
    return FloowerColor._(TinyColor(displayColor));
  }

  static FloowerColor fromHwColor(Color hwColor) {
    TinyColor color = TinyColor(hwColor);
    return FloowerColor._(color.brighten(INTENSITY_SHIFT)); // display intensity up by 30%
  }

  static FloowerColor fromHwRGB(int red, int green, int blue) {
    return FloowerColor._(TinyColor.fromRGB(r: red, g: green, b: blue, a: 255).brighten(INTENSITY_SHIFT)); // display intensity up by 30%
  }

  @override
  String toString() {
    Color color = _displayColor.color;
    return "[${color.red},${color.green},${color.blue}]";
  }
}