import 'dart:async';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:meta/meta.dart';
import 'package:provider/provider.dart';

import 'package:Floower/logic/floower_connector.dart';

class ConnectRoute extends StatelessWidget {
  static const ROUTE_NAME = '/connect';

  @override
  Widget build(BuildContext context) {
    final ConnectRouteArguments args = ModalRoute.of(context).settings.arguments;

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.extraLightBackgroundGray,
      navigationBar: CupertinoNavigationBar(
        middle: Text('Connecting'),
      ),
      child: SafeArea(
        child: Consumer<FloowerConnector>(
          builder: (context, floowerConnector, child) {
            return _ConnectingScreen(
              floowerConnector: floowerConnector,
              device: args.device
            );
          },
        )
      ),
    );
  }
}

class ConnectRouteArguments {
  final DiscoveredDevice device;
  ConnectRouteArguments(this.device);
}

class _ConnectingScreen extends StatefulWidget {

  final FloowerConnector floowerConnector;
  final DiscoveredDevice device;

  const _ConnectingScreen({
    @required this.floowerConnector,
    @required this.device,
    Key key
  }) : super(key: key);

  @override
  _ConnectingScreenState createState() {
    return _ConnectingScreenState();
  }
}

class _ConnectingScreenState extends State<_ConnectingScreen> {

  bool connectingStarted = false;

  @override
  void initState() {
    widget.floowerConnector.connect(widget.device);
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<bool> _disconnect() async {
    await widget.floowerConnector.disconnect();
    return true;
  }

  void _onCancel(BuildContext context) {
    _disconnect();
    Navigator.pop(context); // back to scan screen
  }

  @override
  Widget build(BuildContext context) {
    Widget screen;

    if (widget.floowerConnector.connectionState == FloowerConnectionState.connecting || !connectingStarted) {
      connectingStarted = true;
      screen = _connectingScreen();
    }
    else {
      screen = _connectedScreen();
    }

    return WillPopScope(
      onWillPop: _disconnect,
      child: screen,
    );
  }

  Widget _connectingScreen() {
    final MediaQueryData data = MediaQuery.of(context);

    return _ConnectingScreenLayout(
      title: "Connecting",
      image: Image(
          fit: BoxFit.fitHeight,
          image: AssetImage("assets/images/floower-blossom-bw.png")
      ),
      traling: CupertinoButton.filled(
        child: Text("Cancel"),
        onPressed: () => _onCancel(context)
      ),
      backgroundBuilder: (centerOffset, imageSize) {
        return _CircleAnimation(
          duration: Duration(seconds: 1),
          startRadius: 50,
          endRadius: data.size.height / 2,
          startOpacity: 0.5,
          endOpacity: 0,
          repeat: true,
          color: Colors.blue,
          centerOffset: centerOffset,
          key: ObjectKey(FloowerConnectionState.connecting)
        );
      },
    );
  }

  Widget _connectedScreen() {
    return _ConnectingScreenLayout(
      title: "Connected",
      image: Image(
        fit: BoxFit.fitHeight,
        image: AssetImage("assets/images/floower-blossom.png")
      ),
      traling: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: 18),
            child: Text("What color is your Floower now?"),
          ),
          CupertinoButton.filled(
              child: Text("Yellow"),
              onPressed: () => _onCancel(context)
          ),
          CupertinoButton(
              child: Text("Some other"),
              onPressed: () => _onCancel(context)
          )
        ],
      ),
      backgroundBuilder: (centerOffset, imageSize) {
        return _CircleAnimation(
          duration: Duration(milliseconds: 300),
          startRadius: 50,
          endRadius: imageSize / 2,
          endOpacity: 1,
          color: Colors.yellow,
          centerOffset: centerOffset,
          key: ObjectKey(FloowerConnectionState.connected)
        );
      },
    );
  }
}

class _ConnectingScreenLayout extends StatelessWidget {

  final String title;
  final Widget Function(Offset centerOffset, double imageSize) backgroundBuilder;
  final Widget image;
  final Widget traling;

  _ConnectingScreenLayout({
    @required this.title,
    @required this.backgroundBuilder,
    @required this.image,
    @required this.traling
  });

  @override
  Widget build(BuildContext context) {
    final MediaQueryData data = MediaQuery.of(context);
    final double imageSize = max(data.size.height / 2.6, 200); // magic constant
    final double topOffset = (data.size.height - 500) / 2;
    final Offset centerOffset = Offset(data.size.width / 2, topOffset + imageSize / 2);

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        backgroundBuilder(centerOffset, imageSize),
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
              child: traling
            )
          ],
        ),
      ],
    );
  }
}


class _CircleAnimation extends StatefulWidget {

  final Duration duration;
  final double endRadius;
  final double startRadius;
  final double endOpacity;
  final double startOpacity;
  final Color color;
  final bool repeat;
  final Offset centerOffset;

  _CircleAnimation({
    @required this.duration,
    @required this.endRadius,
    @required this.startRadius,
    this.endOpacity = 1.0,
    this.startOpacity = 1.0,
    this.color = Colors.blue,
    this.repeat = false,
    this.centerOffset,
    Key key
  }) : super(key: key);

  @override
  _CircleAnimationState createState() => _CircleAnimationState();
}

class _CircleAnimationState extends State<_CircleAnimation> with SingleTickerProviderStateMixin {

  Animation<double> _radiusAnimation;
  Animation<double> _opacityAnimation;
  AnimationController _controller;

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
      if (status == AnimationStatus.completed && widget.repeat) {
        _controller.reset();
        _controller.forward();
      }
    });
    //_controller.value;
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