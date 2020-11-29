import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

import 'connect_layout.dart';

class BleConnectInstructions extends StatelessWidget {

  BleConnectInstructions({
    @required this.onStartScan,
    @required this.onDemo,
    Key key
  }) : super(key: key);

  final void Function() onStartScan;
  final void Function() onDemo;

  @override
  Widget build(BuildContext context) {
    final MediaQueryData data = MediaQuery.of(context);
    final double imageSize = max(data.size.height / 2, 200); // magic constant
    final double topOffset = max((data.size.height - (imageSize + 200)) / 2, 70); // magic constant

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            height: topOffset,
            padding: EdgeInsets.only(bottom: 18),
            alignment: Alignment.bottomCenter,
            child: Text("Hold the Leaf", style: CupertinoTheme.of(context).textTheme.navLargeTitleTextStyle)
        ),
        Container(
          constraints: BoxConstraints(maxWidth: 400),
          padding: EdgeInsets.only(bottom: 18, left: 20, right: 20),
          child: Text("Hold your Floower's leaf for 5 seconds\nuntil the blossom starts flashing blue.", textAlign: TextAlign.center),
        ),
        Container(
          width: imageSize,
          height: imageSize,
          child: Image(
            fit: BoxFit.fitHeight,
            image: CupertinoTheme.of(context).brightness == Brightness.dark
                ? AssetImage("assets/images/touch-floower-dark.jpg")
                : AssetImage("assets/images/touch-floower-light.jpg")
          ),
        ),
        CupertinoButton.filled(
            child: Text("It's flashing now"),
            onPressed: onStartScan
        ),
        CupertinoButton(
            child: Text("Let me just play"),
            onPressed: onDemo
        )
      ],
    );
  }
}

class _TouchHandAnimation extends StatefulWidget {

  final Duration duration;
  final double imageSize;
  final Offset centerOffset;

  _TouchHandAnimation({
    @required this.duration,
    @required this.imageSize,
    @required this.centerOffset,
    Key key
  }) : super(key: key);

  @override
  _TouchHandAnimationState createState() => _TouchHandAnimationState();
}

class _TouchHandAnimationState extends State<_TouchHandAnimation> with SingleTickerProviderStateMixin {

  Animation<double> _touchAnimation;
  AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _touchAnimation = Tween<double>(begin: -30, end: -10).animate(_controller);
    _touchAnimation.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _controller.reverse();
      }
      if (status == AnimationStatus.dismissed) {
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
          return Positioned( // using magic constants
              top: widget.centerOffset.dy - widget.imageSize / 2,
              left: widget.centerOffset.dx - widget.imageSize / 2.5 + 10,
              width: widget.imageSize / 1.5,
              height: widget.imageSize,
              child: ClipRect(
                  child: Transform.rotate(
                      angle: 0,
                      //alignment: Alignment.center,
                      child: Transform.translate(
                          offset: Offset(_touchAnimation.value, _touchAnimation.value),
                          child: Image(
                            image: AssetImage("assets/images/touch-floower-light.png"),
                          )
                      )
                  )
              )
          );
        }
    );
  }
}