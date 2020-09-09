import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CupertinoList extends StatelessWidget {

  final List<Widget> children;

  const CupertinoList({
    Key key,
    @required this.children = const <Widget>[],
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      return Container();
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

    return Container(
      padding: EdgeInsets.only(left: 18),
      decoration: const BoxDecoration(
        color: CupertinoColors.white,
        border: Border(
          top: BorderSide(width: 1, color: CupertinoColors.lightBackgroundGray),
          bottom: BorderSide(width: 1, color: CupertinoColors.lightBackgroundGray)
        ),
      ),
      child: Column(
        children: listChildren,
      ),
    );
  }
}

class CupertinoListItem extends StatelessWidget {

  final Widget title;
  final Widget trailling;
  final void Function() onTap;

  const CupertinoListItem({
    Key key,
    @required this.title,
    this.trailling,
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
            trailling != null ? trailling : SizedBox(width: 0)
          ],
        ),
      ),
    );
  }
}

