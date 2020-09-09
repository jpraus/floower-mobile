import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CupertinoList extends StatelessWidget {

  final Widget heading;
  final List<Widget> children;
  final Widget hint;
  final EdgeInsetsGeometry margin;

  const CupertinoList({
    Key key,
    @required this.children = const <Widget>[],
    this.heading,
    this.margin,
    this.hint
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<Widget> column = [];

    if (heading != null) {
      column.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: heading,
      ));
    }

    List<Widget> listChildren = [];
    int index = 0;
    for (Widget child in children) {
      if (index < children.length - 1) {
        listChildren.add(Container(
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(width: 1, color: CupertinoColors.lightBackgroundGray)
            )
          ),
          child: child,
        ));
      }
      else {
        listChildren.add(child);
      }
      index++;
    }

    if (listChildren.isNotEmpty) {
      column.add(Container(
        padding: EdgeInsets.only(left: 18),
        decoration: const BoxDecoration(
          color: CupertinoColors.white,
          border: Border(
              top: BorderSide(
                  width: 1, color: CupertinoColors.lightBackgroundGray),
              bottom: BorderSide(
                  width: 1, color: CupertinoColors.lightBackgroundGray)
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: listChildren,
        ),
      ));
    }

    if (hint != null) {
      column.add(Padding(
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        child: hint,
      ));
    }

    return Container(
      margin: margin,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: column,
      ),
    );
  }
}

class CupertinoListItem extends StatelessWidget {

  final Widget title;
  final Widget trailing;
  final void Function() onTap;

  const CupertinoListItem({
    Key key,
    @required this.title,
    this.trailing,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.only(right: 18, top: 18, bottom: 18),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Expanded(
              child: title
            ),
            trailing != null ? trailing : SizedBox(width: 0)
          ],
        ),
      ),
    );
  }
}

