import 'dart:async';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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

  @override
  void initState() {
    widget.floowerConnector.connect(widget.device);
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _onDiscoveredDeviceTap(DiscoveredDevice device) async {
    Provider.of<FloowerConnector>(context, listen: false).connect(device);
  }

  void _onDeviceDisconnect() async {
    Provider.of<FloowerConnector>(context, listen: false).disconnect();
  }

  void _onCancel(BuildContext context) {
    Provider.of<FloowerConnector>(context, listen: false).disconnect();
    Navigator.pop(context); // back to scan screen
  }

  @override
  Widget build(BuildContext context) {
    final MediaQueryData data = MediaQuery.of(context);
    final double screenHeigth = data.size.height;
    final double imageSize = max(data.size.width / 2, 300);

    List<Widget> column = [];

    column.add(Padding(
      padding: EdgeInsets.only(bottom: 18),
      child: Text(widget.floowerConnector.connectionState == FloowerConnectionState.connecting ? "Connecting" : "Connected", style: CupertinoTheme.of(context).textTheme.navLargeTitleTextStyle),
    ));

    column.add(Image(
      width: imageSize,
      image: AssetImage("assets/images/floower-blossom-bw.png")
    ));

    if (widget.floowerConnector.connectionState == FloowerConnectionState.connecting) {
      column.add(Padding(
        padding: EdgeInsets.only(top: 22),
        child: CupertinoButton.filled(
          child: Text("Cancel"),
          onPressed: () => _onCancel(context)
        )
      ));
    } else {
      column.add(Padding(
        padding: EdgeInsets.only(bottom: 18, top: 18),
        child: Text("What color is your Floower now?"),
      ));
      column.add(CupertinoButton.filled(
          child: Text("Yellow"),
          onPressed: () => _onCancel(context)
      ));
      column.add(CupertinoButton(
          child: Text("Some other"),
          onPressed: () => _onCancel(context)
      ));
    }

    return Stack(
      children: [
        _ConnectedAnimation(
          minRadius: 50,
          maxRadius: screenHeigth / 2,
          maxOpacity: 0.5,
          repeat: true,
          color: Colors.blue,
        ),
        Container(
          alignment: Alignment.topCenter,
          padding: EdgeInsets.only(top: screenHeigth / 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: column,
          ),
        ),
        /*Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Connecting", style: CupertinoTheme.of(context).textTheme.navLargeTitleTextStyle),
              SizedBox(height: 40),
              CupertinoButton.filled(
                child: Text("Cancel"),
                onPressed: () => _onCancel(context)
              ),
            ],
          ),
        ),*/
      ],
    );
  }
}

class _ConnectedAnimation extends StatefulWidget {

  final double maxRadius;
  final double minRadius;
  final double maxOpacity;
  final Color color;
  final bool repeat;

  _ConnectedAnimation({
    @required this.maxRadius,
    @required this.minRadius,
    this.maxOpacity = 1.0,
    this.color = Colors.lightGreenAccent,
    this.repeat = false
  });

  @override
  _ConnectedAnimationState createState() => _ConnectedAnimationState();
}

class _ConnectedAnimationState extends State<_ConnectedAnimation> with SingleTickerProviderStateMixin {

  Animation<double> _radiusAnimation;
  Animation<double> _opacityAnimation;
  AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    );

    _opacityAnimation = Tween<double>(begin: widget.maxOpacity, end: 0).animate(_controller);
    _radiusAnimation = Tween<double>(begin: widget.minRadius, end: widget.maxRadius).animate(_controller);
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
            color: widget.color.withOpacity(_opacityAnimation.value)
          )
        );
      }
    );
  }
}

class _DrawCenteredCircle extends CustomPainter {

  double radius;
  Color color;

  _DrawCenteredCircle({this.radius, this.color});

  @override
  void paint(Canvas canvas, Size size) {
    Paint brush = new Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.fill
      ..strokeWidth = 30;
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), radius, brush);
  }

  @override
  bool shouldRepaint(_DrawCenteredCircle oldDelegate) {
    return oldDelegate.radius != radius || oldDelegate.color != color;
  }
}