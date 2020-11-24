import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:meta/meta.dart';

import 'connect_layout.dart';

class FloowerConnecting extends StatelessWidget {

  FloowerConnecting({
    @required this.onCancel,
    Key key
  }) : super(key: key);

  final void Function() onCancel;

  @override
  Widget build(BuildContext context) {
    final MediaQueryData data = MediaQuery.of(context);

    return ConnectLayout(
      title: "Connecting",
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
}

class FloowerConnected extends StatelessWidget {

  FloowerConnected({
    @required this.onCancel,
    @required this.onPair,
    this.color,
    Key key
  }) : super(key: key);

  final Color color;
  final void Function() onCancel;
  final void Function() onPair;

  @override
  Widget build(BuildContext context) {
    final MediaQueryData data = MediaQuery.of(context);

    return ConnectLayout(
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
              onPressed: onPair
          ),
          CupertinoButton(
              child: Text("Not, it's not"),
              onPressed: onCancel
          )
        ],
      ),
      backgroundBuilder: (centerOffset, imageSize) {
        return Stack(
          children: [
            CircleAnimation(
                duration: Duration(milliseconds: 300),
                startRadius: 50,
                endRadius: imageSize / 2,
                endOpacity: 1,
                color: color,
                centerOffset: centerOffset,
                key: UniqueKey()
            ),
            CircleAnimation(
                duration: Duration(milliseconds: 1000),
                startRadius: 200,
                endRadius: data.size.height,
                startOpacity: 0.4,
                endOpacity: 0,
                color: color,
                centerOffset: centerOffset,
                key: UniqueKey()
            ),
            CircleAnimation(
                duration: Duration(milliseconds: 1000),
                startRadius: 50,
                endRadius: data.size.height,
                startOpacity: 0.5,
                endOpacity: 0,
                color: color,
                centerOffset: centerOffset,
                key: UniqueKey()
            )
          ],
        );
      },
    );
  }
}

class FloowerConnectFailed extends StatelessWidget {

  FloowerConnectFailed({
    @required this.onCancel,
    @required this.onReconnect,
    this.message,
    Key key
  }) : super(key: key);

  final String message;
  final void Function() onCancel;
  final void Function() onReconnect;

  @override
  Widget build(BuildContext context) {
    final MediaQueryData data = MediaQuery.of(context);

    return ConnectLayout(
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
            child: Text(message ?? "Cannot connect to selected Floower"),
          ),
          CupertinoButton.filled(
              child: Text("Try again"),
              onPressed: onReconnect
          ),
          CupertinoButton(
              child: Text("Choose another"),
              onPressed: onCancel
          )
        ],
      ),
      backgroundBuilder: (centerOffset, imageSize) {
        return Stack(
          children: [
            CircleAnimation(
                duration: Duration(milliseconds: 300),
                startRadius: 50,
                endRadius: data.size.height,
                endOpacity: 0,
                color: Colors.red,
                centerOffset: centerOffset,
                key: UniqueKey()
            ),
            CircleAnimation(
                duration: Duration(milliseconds: 1000),
                startRadius: 200,
                endRadius: data.size.height,
                startOpacity: 0.4,
                endOpacity: 0,
                color: Colors.red,
                centerOffset: centerOffset,
                key: UniqueKey()
            ),
            CircleAnimation(
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