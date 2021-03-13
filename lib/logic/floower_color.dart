import 'package:flutter/material.dart';

class FloowerColor {

  // pre-defined colors, keep in sync with firmware
  static FloowerColor COLOR_RED = FloowerColor.fromHSV(0.0, 1.0, 1.0);
  static FloowerColor COLOR_GREEN = FloowerColor.fromHSV(106.0, 1.0, 1.0);
  static FloowerColor COLOR_BLUE = FloowerColor.fromHSV(218.0, 1.0, 1.0);
  static FloowerColor COLOR_YELLOW = FloowerColor.fromHSV(57.0, 1.0, 1.0);
  static FloowerColor COLOR_ORANGE = FloowerColor.fromHSV(22.0, 1.0, 1.0);
  static FloowerColor COLOR_WHITE = FloowerColor.fromHSV(0.0, 0.0, 1.0);
  static FloowerColor COLOR_PURPLE = FloowerColor.fromHSV(299.0, 1.0, 1.0);
  static FloowerColor COLOR_PINK = FloowerColor.fromHSV(335.0, 1.0, 1.0);
  static FloowerColor COLOR_BLACK = FloowerColor.fromHSV(0.0, 0.0, 0.0);

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

  final HSVColor _color;

  FloowerColor(this._color);

  HSVColor get color => _color;
  Color toColor() => _color.toColor();
  Color toColorWithAlpha(double alpha) => _color.withAlpha(alpha).toColor();

  bool isBlack() {
    return _color.value == 0;
  }

  bool isDark() {
    return this.getBrightness() < 128.0;
  }

  bool isLight() {
    return !isDark();
  }

  double getBrightness() {
    Color color = _color.toColor();
    return (color.red * 299 + color.green * 587 + color.blue * 114) / 1000;
  }

  static FloowerColor fromColor(Color hwColor) {
    if (hwColor.red == 0 && hwColor.green == 0 && hwColor.blue == 0) {
      return COLOR_BLACK;
    }
    return FloowerColor(HSVColor.fromColor(hwColor));
  }

  static FloowerColor fromRGB(int red, int green, int blue) {
    return FloowerColor(HSVColor.fromColor(Color.fromARGB(255, red, green, blue)));
  }

  static FloowerColor fromHSV(double hue, double saturation, double value) {
    return FloowerColor(HSVColor.fromAHSV(1.0, hue, saturation, value));
  }

  @override
  String toString() {
    Color color = _color.toColor();
    return "[${color.alpha},${color.red},${color.green},${color.blue}]";
  }
}