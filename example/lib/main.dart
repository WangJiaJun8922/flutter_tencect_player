import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tencent_video_player/controller/tencent_player_controller.dart';
import 'package:flutter_tencent_video_player/view/tencent_player.dart';

void main() => runApp(MyApp());

enum PlayType {
  network,
  asset,
  file,
  fileId,
}

class MyApp extends StatefulWidget {
  PlayType playType;
  String dataSource;

  MyApp({this.dataSource, this.playType = PlayType.network});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  TencentPlayerController controller;
  VoidCallback listener;

  _MyAppState() {
    listener = () {
      if (!mounted) {
        return;
      }
      setState(() {});
    };
  }

  @override
  void initState() {
    super.initState();
    controller = TencentPlayerController.network(
        'http://media.yangqungongshe.com/sv/a756272-170393e8e78/a756272-170393e8e78.mp4',
        deviceOrientationsAfterFullScreen: [DeviceOrientation.portraitUp]);
    controller.initialize();
    controller.addListener(listener);
  }

  @override
  Future dispose() {
    super.dispose();
    controller.removeListener(listener);
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: controller.value.initialized ? AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: TencentPlayer(controller),
          ): Container()
        ),
      ),
    );
  }
}
