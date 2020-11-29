import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class FloowerTextTheme {

  static TextStyle listTitle(BuildContext context) {
    return CupertinoTheme.of(context).textTheme.textStyle
        .copyWith(color: secondaryColor(), fontSize: 14);
  }

  static TextStyle secondaryLabel(BuildContext context) {
    return CupertinoTheme.of(context).textTheme.textStyle
        .copyWith(color: secondaryColor());
  }

  static Color secondaryColor() {
    return isDarkMode()
        ? CupertinoColors.secondaryLabel.darkColor
        : CupertinoColors.secondaryLabel.color;
  }

  static bool isDarkMode() {
    return WidgetsBinding.instance.window.platformBrightness == Brightness.dark;
  }
}