import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock/wakelock.dart';
import '../controller/tencent_player_controller.dart';

class TencentPlayer extends StatefulWidget {
  final TencentPlayerController controller;

  TencentPlayer(this.controller);

  static MethodChannel channel = const MethodChannel('flutter_tencent_video_player')
    ..invokeMethod<void>('init');

  @override
  _TencentPlayerState createState() => _TencentPlayerState();
}

class _TencentPlayerState extends State<TencentPlayer> {
  VoidCallback _listener;
  VoidCallback _fullScreenListener;
  int _textureId;
  bool _isFullScreen = false;

  _TencentPlayerState() {
    _listener = () async {
      final int newTextureId = widget.controller.textureId;
      if (newTextureId != _textureId) {
        setState(() {
          _textureId = newTextureId;
        });
      }
    };
    _fullScreenListener = () async {
      if(widget.controller.value.isFullScreen && !_isFullScreen) {
        _isFullScreen = true;
        await _pushFullScreenWidget(context);
      } else if (!widget.controller.value.isFullScreen && _isFullScreen) {
        Navigator.of(context, rootNavigator: true).pop();
        _isFullScreen = false;
      }
    };
  }

  Future<dynamic> _pushFullScreenWidget(BuildContext context) async {
    final isAndroid = Theme.of(context).platform == TargetPlatform.android;
    final TransitionRoute<Null> route = PageRouteBuilder<Null>(
      settings: RouteSettings(isInitialRoute: false),
      pageBuilder: _fullScreenRoutePageBuilder,
    );

    SystemChrome.setEnabledSystemUIOverlays([]);
    if (isAndroid) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }

    Wakelock.enable();

    await Navigator.of(context, rootNavigator: true).push(route);
    _isFullScreen = false;
    widget.controller.exitFullScreen();

    // The wakelock plugins checks whether it needs to perform an action internally,
    // so we do not need to check Wakelock.isEnabled.
    Wakelock.disable();

    SystemChrome.setEnabledSystemUIOverlays(widget.controller.systemOverlaysAfterFullScreen);
    SystemChrome.setPreferredOrientations(widget.controller.deviceOrientationsAfterFullScreen);
  }

  Widget _fullScreenRoutePageBuilder(
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      ) {
    var controllerProvider = TencentPlayerControllerProvider(
      controller: widget.controller,
      child: Stack(
        children: <Widget>[
          Container(width: double.infinity,height: double.infinity,color: Colors.black,),
          _textureId == null ? Container() : Center(child: AspectRatio(aspectRatio: widget.controller.value.aspectRatio,child: Texture(textureId: _textureId))),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              height: 30,
              width: 30,
              margin: EdgeInsets.only(right: 15, bottom: 5),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(15),color: Colors.black.withOpacity(0.6)),
              child: GestureDetector(
                child: Icon(Icons.fullscreen_exit, color: Colors.white),
                onTap: () {
                  widget.controller.exitFullScreen();
                },
              ),
            ),
          )
        ],
      ),
    );

    return _defaultRoutePageBuilder(
        context, animation, secondaryAnimation, controllerProvider);
  }

  AnimatedWidget _defaultRoutePageBuilder(BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      TencentPlayerControllerProvider controllerProvider) {
    return AnimatedBuilder(
      animation: animation,
      builder: (BuildContext context, Widget child) {
        return _buildFullScreenVideo(context, animation, controllerProvider);
      },
    );
  }

  Widget _buildFullScreenVideo(
      BuildContext context,
      Animation<double> animation,
      TencentPlayerControllerProvider controllerProvider) {
    return Scaffold(
      resizeToAvoidBottomPadding: false,
      body: Container(
        alignment: Alignment.center,
        color: Colors.black,
        child: controllerProvider,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _textureId = widget.controller.textureId;
    widget.controller.addListener(_listener);
    widget.controller.addListener(_fullScreenListener);
  }

  @override
  void didUpdateWidget(TencentPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller.dataSource != widget.controller.dataSource) {
      if(Platform.isAndroid) oldWidget.controller.dispose();
    }
    oldWidget.controller.removeListener(_listener);
    oldWidget.controller.removeListener(_fullScreenListener);
    _textureId = widget.controller.textureId;
    widget.controller.addListener(_listener);
    widget.controller.addListener(_fullScreenListener);
  }

  @override
  void deactivate() {
    super.deactivate();
    widget.controller.removeListener(_listener);
    widget.controller.removeListener(_fullScreenListener);
  }

  @override
  Widget build(BuildContext context) {
    return TencentPlayerControllerProvider(
      controller: widget.controller,
      child: Stack(
        children: <Widget>[
          _textureId == null ? Container() : AspectRatio(aspectRatio: widget.controller.value.aspectRatio,child: Texture(textureId: _textureId)),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              height: 30,
              width: 30,
              margin: EdgeInsets.only(right: 5, bottom: 5),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(15),color: Colors.black.withOpacity(0.6)),
              child: GestureDetector(
                child: Icon(Icons.fullscreen, color: Colors.white),
                onTap: () {
                  widget.controller.enterFullScreen();
                },
              ),
            ),
          )
        ],
      ),
    );
    //return _textureId == null ? Container() : Texture(textureId: _textureId);
  }
}
