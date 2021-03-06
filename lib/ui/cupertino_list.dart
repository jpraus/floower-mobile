import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:Floower/ui/commons.dart';

class CupertinoList extends StatelessWidget {

  final Widget heading;
  final List<Widget> children;
  final Widget hint;
  final EdgeInsetsGeometry margin;

  const CupertinoList({
    Key key,
    this.children = const <Widget>[],
    this.heading,
    this.margin,
    this.hint
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<Widget> column = [];

    if (heading != null) {
      column.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
        child: DefaultTextStyle(
          style: FloowerTextTheme.listTitle(context),
          child: heading,
        )
      ));
    }

    if (children.isNotEmpty) {
      column.add(Padding(
        padding: EdgeInsets.only(left: 18, right: 18),
        child: ClipRRect(
          clipBehavior: Clip.antiAlias,
          borderRadius: BorderRadius.circular(10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: children,
          ),
        ),
      ));
    }

    if (hint != null) {
      column.add(Padding(
        padding: EdgeInsets.symmetric(vertical: 18, horizontal: 18),
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

class CupertinoListItem extends StatefulWidget {

  final Widget leading;
  final Widget title;
  final Widget trailing;
  final void Function() onTap;
  final double paddingTop;
  final double paddingBottom;

  const CupertinoListItem({
    Key key,
    this.leading,
    @required this.title,
    this.trailing,
    this.onTap,
    this.paddingTop,
    this.paddingBottom
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _CupertinoListItemState();
  }
}

class _CupertinoListItemState extends State<CupertinoListItem> {

  Color _color;

  void _onTapDown(TapDownDetails tapDownDetails) {
    setState(() => _color = CupertinoTheme.of(context).scaffoldBackgroundColor);
  }

  void _onTapUp(TapUpDetails tapUpDetails) {
    setState(() => _color = CupertinoTheme.of(context).barBackgroundColor);
  }

  void _onTapCancel() {
    setState(() => _color = CupertinoTheme.of(context).barBackgroundColor);
  }

  @override
  Widget build(BuildContext context) {
    if (_color == null) {
      _color = CupertinoTheme.of(context).barBackgroundColor;
    }

    return GestureDetector(
      onTapDown: widget.onTap != null ? _onTapDown : null,
      onTapUp: widget.onTap != null ? _onTapUp : null,
      onTapCancel: widget.onTap != null ? _onTapCancel : null,
      onTap: widget.onTap,
      child: AnimatedContainer(
        decoration: BoxDecoration(
          color: _color,
        ),
        duration: Duration(milliseconds: 50),
        child: Padding(
          padding: EdgeInsets.only(left: 22, right: 22, top: widget.paddingTop ?? 22, bottom: widget.paddingBottom ?? 22),
          child: DefaultTextStyle(
            style: CupertinoTheme.of(context).textTheme.textStyle,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                widget.leading != null ? widget.leading : SizedBox(width: 0),
                Expanded(
                  child: widget.title
                ),
                widget.trailing != null ? widget.trailing : SizedBox(width: 0)
              ],
            ),
          ),
        ),
      ),
    );
  }
}

