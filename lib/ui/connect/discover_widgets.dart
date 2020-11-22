import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:meta/meta.dart';

import 'package:Floower/ui/commons.dart';
import 'package:Floower/ui/connect/device.dart';
import 'package:Floower/ui/connect/connect_layout.dart';
import 'package:Floower/ui/cupertino_list.dart';

class BleScanning extends StatelessWidget {

  BleScanning({
    @required this.onCancel,
    Key key
  }) : super(key: key);

  final void Function() onCancel;

  @override
  Widget build(BuildContext context) {
    return ConnectLayout(
      title: "Searching ...",
      image: Image(
          fit: BoxFit.fitHeight,
          image: AssetImage("assets/images/floower-blossom.png")
      ),
      trailing: CupertinoButton.filled(
          child: Text("Cancel"),
          onPressed: onCancel
      ),
      backgroundBuilder: (centerOffset, imageSize) {
        return CircleAnimation(
            duration: Duration(milliseconds: 500),
            startRadius: (imageSize / 2) - 50,
            endRadius: imageSize / 2,
            startOpacity: 0,
            endOpacity: 0.5,
            repeat: true,
            boomerang: true,
            color: Colors.blue,
            centerOffset: centerOffset,
            key: new GlobalKey()
        );
      },
    );
  }
}

class BleScanList extends StatelessWidget {

  BleScanList({
    @required this.discoveredDevices,
    @required this.scanIsInProgress,
    @required this.onScanStart,
    @required this.onScanStop,
    @required this.onDeviceConnect,
    Key key
  }) : super(key: key);

  final List<DiscoveredDevice> discoveredDevices;
  final bool scanIsInProgress;
  final void Function() onScanStart;
  final void Function() onScanStop;
  final void Function(DiscoveredDevice device) onDeviceConnect;

  @override
  Widget build(BuildContext context) {
    List<Widget> column = [];

    // discovered devices
    List<Widget> devices = [];
    for (DiscoveredDevice device in discoveredDevices) {
      devices.add(new DiscoveredDeviceListItem(
          device: device,
          onTap: onDeviceConnect
      ));
    }

    column.add(CupertinoList(
        margin: EdgeInsets.only(top: 18),
        heading: GestureDetector(
          child: Row(
            children: <Widget>[
              Text(scanIsInProgress
                  ? "SCANNING FOR DEVICES"
                  : "DISCOVERED DEVICES", style: FloowerTextTheme.listLabel),
              const SizedBox(width: 10),
              scanIsInProgress
                  ? CupertinoActivityIndicator()
                  : Icon(CupertinoIcons.refresh),
            ],
          ),
          onTap:
          scanIsInProgress
              ? onScanStop
              : onScanStart,
        ),
        //hint: discoveredDevices.isNotEmpty ? const Text("Tap the device to connect", style: FloowerTextTheme.listLabel) : null,
        children: devices
    ));

    return ListView(
      children: column,
    );
  }
}

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
        duration: Duration(seconds: 2),
        key: new GlobalKey()
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