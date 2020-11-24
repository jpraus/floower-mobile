import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:meta/meta.dart';

class ConnectLayout extends StatelessWidget {

  final String title;
  final Widget Function(Offset centerOffset, double imageSize) animationBuilder;
  final Widget image;
  final Widget Function(Offset centerOffset, double imageSize) backgroundBuilder;
  final Widget trailing;

  ConnectLayout({
    @required this.title,
    this.animationBuilder,
    @required this.image,
    this.backgroundBuilder,
    @required this.trailing,
    Key key
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final MediaQueryData data = MediaQuery.of(context);
    final double imageSize = max(data.size.height / 2.6, 200); // magic constant
    final double topOffset = max((data.size.height - (imageSize + 200)) / 2, 70); // magic constant
    final Offset centerOffset = Offset(data.size.width / 2, topOffset + imageSize / 2);

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        backgroundBuilder != null ? backgroundBuilder(centerOffset, imageSize) : SizedBox(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: topOffset,
              padding: EdgeInsets.only(bottom: 18),
              alignment: Alignment.bottomCenter,
              child: Text(title, style: CupertinoTheme.of(context).textTheme.navLargeTitleTextStyle)
            ),
            Container(
              width: imageSize,
              height: imageSize,
              child: image,
            ),
            Padding(
              padding: EdgeInsets.only(top: 28),
              child: trailing
            )
          ],
        ),
        animationBuilder != null ? animationBuilder(centerOffset, imageSize) : SizedBox(),
      ],
    );
  }
}

class CircleAnimation extends StatefulWidget {

  final Duration duration;
  final double endRadius;
  final double startRadius;
  final double endOpacity;
  final double startOpacity;
  final Color color;
  final bool repeat;
  final bool boomerang;
  final Offset centerOffset;

  CircleAnimation({
    @required this.duration,
    @required this.endRadius,
    @required this.startRadius,
    this.endOpacity = 1.0,
    this.startOpacity = 1.0,
    this.color = Colors.blue,
    this.repeat = false,
    this.boomerang = false,
    this.centerOffset,
    Key key
  }) : super(key: key);

  @override
  CircleAnimationState createState() => CircleAnimationState();
}

class CircleAnimationState extends State<CircleAnimation> with SingleTickerProviderStateMixin {

  Animation<double> _radiusAnimation;
  Animation<double> _opacityAnimation;
  AnimationController _controller;
  bool _forward = true;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _opacityAnimation = Tween<double>(begin: widget.startOpacity, end: widget.endOpacity).animate(_controller);
    _radiusAnimation = Tween<double>(begin: widget.startRadius, end: widget.endRadius).animate(_controller);
    _radiusAnimation.addStatusListener((status) {
      if (status == AnimationStatus.completed && (widget.repeat || widget.boomerang)) {
        if (widget.boomerang) {
          _controller.reverse();
        }
        else {
          _controller.reset();
          _controller.forward();
        }
      }
      if (status == AnimationStatus.dismissed && widget.boomerang && widget.repeat) {
        _controller.reset();
        _controller.forward();
      }
    });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size.infinite,
          painter: _DrawCenteredCircle(
            radius: _radiusAnimation.value,
            color: widget.color.withOpacity(_opacityAnimation.value),
            centerOffset: widget.centerOffset,
          )
        );
      }
    );
  }
}

class _DrawCenteredCircle extends CustomPainter {

  final Offset centerOffset;
  final double radius;
  final Color color;

  _DrawCenteredCircle({this.radius, this.color, this.centerOffset});

  @override
  void paint(Canvas canvas, Size size) {
    Paint brush = new Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.fill
      ..strokeWidth = 30;
    canvas.drawCircle(centerOffset, radius, brush);
  }

  @override
  bool shouldRepaint(_DrawCenteredCircle oldDelegate) {
    return oldDelegate.radius != radius || oldDelegate.color != color;
  }
}