import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tc_player/flutter_tc_player.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
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
  void dispose() {
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
