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
        child: _ConnectingScreen(
          device: args.device
        ),
      ),
    );
  }
}

class ConnectRouteArguments {
  final DiscoveredDevice device;
  ConnectRouteArguments(this.device);
}

class _ConnectingScreen extends StatefulWidget {

  final DiscoveredDevice device;

  const _ConnectingScreen({
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

    FloowerConnector floowerConnector = Provider.of<FloowerConnector>(context);
    if (!connectingStarted) {
      floowerConnector.connect(widget.device);
      connectingStarted = true;
    }

    return Stack(
      children: [
        _ConnectedAnimation(),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Connected", style: CupertinoTheme.of(context).textTheme.navLargeTitleTextStyle),
              SizedBox(height: 18),
              /*ColorFiltered(
                child: Image(
                  width: max(data.size.width / 2, 300),
                  image: AssetImage("assets/images/floower-yellow.png")
                ),
                colorFilter: ColorFilter.mode(Colors.yellow, BlendMode.modulate),
              ),*/
              Image(
                  width: max(data.size.width / 2, 300),
                  image: AssetImage("assets/images/floower-yellow.png")
              ),
              SizedBox(height: 18),
              Text("What color is your Floower now?"),
              SizedBox(height: 18),
              CupertinoButton.filled(
                  child: Text("Yellow"),
                  onPressed: () => _onCancel(context)
              ),
              CupertinoButton(
                  child: Text("Some other"),
                  onPressed: () => _onCancel(context)
              ),
            ],
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
  @override
  _ConnectedAnimationState createState() => _ConnectedAnimationState();
}

class _ConnectedAnimationState extends State<_ConnectedAnimation> with SingleTickerProviderStateMixin {

  Animation<double> _animation;
  AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 400),
    );

    _animation = Tween<double>(begin: 0, end: 20).animate(_controller);
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
        return Transform.scale(
          scale: _animation.value,
          child: child,
        );
        return CustomPaint(
          size: Size.infinite,
          painter: _DrawCenteredCircle(
            radius: _animation.value,
            color: Colors.lightGreenAccent
          )
        );
      },
      child: CustomPaint(
        size: Size.infinite,
        painter: _DrawCenteredCircle(
          radius: 10,
          color: Colors.yellow
        )
      ),
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
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}