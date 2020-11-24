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
    return ConnectLayout(
      title: "Hold the Leaf",
      image: Image(
          fit: BoxFit.fitHeight,
          image: AssetImage("assets/images/leaf.png")
      ),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            constraints: BoxConstraints(maxWidth: 400),
            padding: EdgeInsets.only(bottom: 18, left: 20, right: 20),
            child: Text("Hold your Floower's leaf for 5 seconds until\nthe blossom starts flashing blue.", textAlign: TextAlign.center),
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
      ),
      animationBuilder: (centerOffset, imageSize) => _TouchHandAnimation(
          centerOffset: centerOffset,
          imageSize: imageSize,
          duration: Duration(seconds: 2)
      ),
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
                            image: AssetImage("assets/images/touch-hand.png"),
                          )
                      )
                  )
              )
          );
        }
    );
  }
}