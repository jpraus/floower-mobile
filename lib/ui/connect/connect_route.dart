import 'dart:async';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:meta/meta.dart';
import 'package:provider/provider.dart';

import 'package:Floower/ui/home_route.dart';
import 'package:Floower/logic/floower_connector.dart';

class ConnectRoute extends StatelessWidget {
  static const ROUTE_NAME = '/connect';

  @override
  Widget build(BuildContext context) {
    final ConnectRouteArguments args = ModalRoute.of(context).settings.arguments;

    return CupertinoPageScaffold(
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

  _ConnectionState _state = _ConnectionState.connecting;
  bool _connectingStarted = false;
  bool _disconnectingStarted = false;
  String _failedMessage;

  @override
  void initState() {
    widget.floowerConnector.connect(widget.device);
    widget.floowerConnector.addListener(_onFloowerConnectorChange);
    super.initState();
  }

  @override
  void dispose() {
    widget.floowerConnector.removeListener(_onFloowerConnectorChange);
    super.dispose();
  }

  void _onFloowerConnectorChange() {
    bool canFail = _connectingStarted && !_disconnectingStarted;

    if (widget.floowerConnector.connectionState == FloowerConnectionState.connecting) {
      _connectingStarted = true;
    }
    else if (widget.floowerConnector.connectionState == FloowerConnectionState.pairing) {
      _onDevicePairing();
    }
    else if (canFail && (widget.floowerConnector.connectionState == FloowerConnectionState.disconnecting || widget.floowerConnector.connectionState == FloowerConnectionState.disconnected)) {
      setState(() => _state = _ConnectionState.failed);
    }
  }

  void _onDevicePairing() async {
    setState(() => _state = _ConnectionState.pairing);

    Duration transitionDuration = const Duration(milliseconds: 500);
    Color color = FloowerConnector.COLOR_YELLOW.hwColor;

    // try to send pairing command to change color and open a bit
    WriteResult result = await widget.floowerConnector.writeState(openLevel: 20, color: color, duration: transitionDuration);
    if (!result.success) {
      setState(() {
        _failedMessage = result.errorMessage;
        _state = _ConnectionState.failed;
      });
    }
    else {
      // if success close again
      await new Future.delayed(transitionDuration);
      await widget.floowerConnector.writeState(openLevel: 0, color: color, duration: transitionDuration);

      setState(() => _state = _ConnectionState.paired);
    }
  }

  Future<bool> _disconnect() async {
    _disconnectingStarted = true;
    await widget.floowerConnector.disconnect();
    return true;
  }

  void _onCancel(BuildContext context) {
    _disconnect();
    Navigator.pop(context); // back to scan screen
  }

  void _onReconnect(BuildContext context) {
    widget.floowerConnector.connect(widget.device);
    setState(() => _state = _ConnectionState.connecting);
  }

  void _onPair(BuildContext context) async {
    await widget.floowerConnector.writeState(openLevel: 0, color: Colors.black, duration: Duration(milliseconds: 500));
    widget.floowerConnector.pair();
    Navigator.popUntil(context, ModalRoute.withName(HomeRoute.ROUTE_NAME));
  }

  @override
  Widget build(BuildContext context) {
    Widget screen;

    switch (_state) {
      case _ConnectionState.connecting:
      case _ConnectionState.pairing:
        screen = _connectingScreen();
        break;

      case _ConnectionState.paired:
        screen = _connectedScreen();
        break;

      case _ConnectionState.failed:
        screen = _failedScreen();
        break;
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
      trailing: CupertinoButton.filled(
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
          key: UniqueKey()
        );
      },
    );
  }

  Widget _connectedScreen() {
    final MediaQueryData data = MediaQuery.of(context);

    return _ConnectingScreenLayout(
      title: "Connected",
      image: Image(
        fit: BoxFit.fitHeight,
        image: AssetImage("assets/images/floower-blossom.png")
      ),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: 18),
            child: Text("Is your Floower yellow now?"),
          ),
          CupertinoButton.filled(
              child: Text("Yes"),
              onPressed: () => _onPair(context)
          ),
          CupertinoButton(
              child: Text("Not, it's not"),
              onPressed: () => _onCancel(context)
          )
        ],
      ),
      backgroundBuilder: (centerOffset, imageSize) {
        return Stack(
          children: [
            _CircleAnimation(
                duration: Duration(milliseconds: 300),
                startRadius: 50,
                endRadius: imageSize / 2,
                endOpacity: 1,
                color: FloowerConnector.COLOR_YELLOW.displayColor,
                centerOffset: centerOffset,
                key: UniqueKey()
            ),
            _CircleAnimation(
                duration: Duration(milliseconds: 1000),
                startRadius: 200,
                endRadius: data.size.height,
                startOpacity: 0.4,
                endOpacity: 0,
                color: FloowerConnector.COLOR_YELLOW.displayColor,
                centerOffset: centerOffset,
                key: UniqueKey()
            ),
            _CircleAnimation(
              duration: Duration(milliseconds: 1000),
              startRadius: 50,
              endRadius: data.size.height,
              startOpacity: 0.5,
              endOpacity: 0,
              color: FloowerConnector.COLOR_YELLOW.displayColor,
              centerOffset: centerOffset,
              key: UniqueKey()
            )
          ],
        );
      },
    );
  }

  Widget _failedScreen() {
    final MediaQueryData data = MediaQuery.of(context);

    return _ConnectingScreenLayout(
      title: "Failed",
      image: Image(
          fit: BoxFit.fitHeight,
          image: AssetImage("assets/images/floower-blossom-bw.png")
      ),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: 18),
            child: Text(_failedMessage ?? "Cannot connect to selected Floower"),
          ),
          CupertinoButton.filled(
              child: Text("Try again"),
              onPressed: () => _onReconnect(context)
          ),
          CupertinoButton(
              child: Text("Choose another"),
              onPressed: () => _onCancel(context)
          )
        ],
      ),
      backgroundBuilder: (centerOffset, imageSize) {
        return Stack(
          children: [
            _CircleAnimation(
                duration: Duration(milliseconds: 300),
                startRadius: 50,
                endRadius: data.size.height,
                endOpacity: 0,
                color: Colors.red,
                centerOffset: centerOffset,
                key: UniqueKey()
            ),
            _CircleAnimation(
                duration: Duration(milliseconds: 1000),
                startRadius: 200,
                endRadius: data.size.height,
                startOpacity: 0.4,
                endOpacity: 0,
                color: Colors.red,
                centerOffset: centerOffset,
                key: UniqueKey()
            ),
            _CircleAnimation(
                duration: Duration(milliseconds: 1000),
                startRadius: 50,
                endRadius: data.size.height,
                startOpacity: 0.5,
                endOpacity: 0,
                color: Colors.red,
                centerOffset: centerOffset,
                key: UniqueKey()
            )
          ],
        );
      },
    );
  }
}

class _ConnectingScreenLayout extends StatelessWidget {

  final String title;
  final Widget Function(Offset centerOffset, double imageSize) backgroundBuilder;
  final Widget image;
  final Widget trailing;

  _ConnectingScreenLayout({
    @required this.title,
    @required this.backgroundBuilder,
    @required this.image,
    @required this.trailing
  });

  @override
  Widget build(BuildContext context) {
    final MediaQueryData data = MediaQuery.of(context);
    final double imageSize = max(data.size.height / 2.6, 200); // magic constant
    final double topOffset = max((data.size.height - (imageSize + 200)) / 2, 70); // magic constant
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
              child: trailing
            )
          ],
        ),
      ],
    );
  }
}

/// Connection state
enum _ConnectionState {
  connecting,
  pairing,
  paired,
  failed
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