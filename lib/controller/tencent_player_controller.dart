import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tencent_video_player/model/player_config.dart';
import 'package:flutter_tencent_video_player/model/tencent_player_value.dart';
import '../view/tencent_player.dart';

class TencentPlayerController extends ValueNotifier<TencentPlayerValue> {
  // 唯一id
  int _textureId;
  // 播放地址
  final String dataSource;
  // 地址类型
  final DataSourceType dataSourceType;
  // 播放器设置
  final PlayerConfig playerConfig;
  MethodChannel channel = TencentPlayer.channel;

  // 组件是否已销毁
  bool _isDisposed = false;
  // 视频组件创建完成
  Completer<void> _creatingCompleter;
  // 监听事件
  StreamSubscription<dynamic> _eventSubscription;
  // App生命周期监听(后台，前台)
  _VideoAppLifeCycleObserver _lifeCycleObserver;

  /// 定义退出全屏后可见的系统覆盖
  final List<SystemUiOverlay> systemOverlaysAfterFullScreen;

  /// 退出全屏后定义一组允许的设备方向
  final List<DeviceOrientation> deviceOrientationsAfterFullScreen;

  // 返回渲染id唯一
  int get textureId => _textureId;


  TencentPlayerController.asset(
      this.dataSource,
      {this.playerConfig = const PlayerConfig(), this.systemOverlaysAfterFullScreen = SystemUiOverlay.values, this.deviceOrientationsAfterFullScreen = const [
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]})
      : dataSourceType = DataSourceType.asset, super(TencentPlayerValue());

  TencentPlayerController.network(this.dataSource,
      {this.playerConfig = const PlayerConfig(), this.systemOverlaysAfterFullScreen = SystemUiOverlay.values, this.deviceOrientationsAfterFullScreen = const [
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]})
      : dataSourceType = DataSourceType.network, super(TencentPlayerValue());

  TencentPlayerController.file(String filePath,
      {this.playerConfig = const PlayerConfig(), this.systemOverlaysAfterFullScreen = SystemUiOverlay.values, this.deviceOrientationsAfterFullScreen = const [
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]})
      : dataSource = filePath, dataSourceType = DataSourceType.file, super(TencentPlayerValue());

  static TencentPlayerController of(BuildContext context) {
    final tencentControllerProvider =
    context.dependOnInheritedWidgetOfExactType<TencentPlayerControllerProvider>();
    return tencentControllerProvider.controller;
  }

  /// 初始化
  Future<void> initialize() async {
    _lifeCycleObserver = _VideoAppLifeCycleObserver(this);
    _lifeCycleObserver.initialize();
    _creatingCompleter = Completer<void>();
    Map<dynamic, dynamic> dataSourceDescription;
    switch (dataSourceType) {
      case DataSourceType.asset:
        dataSourceDescription = <String, dynamic>{'asset': dataSource};
        break;
      case DataSourceType.network:
      case DataSourceType.file:
        dataSourceDescription = <String, dynamic>{'uri': dataSource};
        break;
    }
    value = value.copyWith(isPlaying: playerConfig.autoPlay);
    dataSourceDescription.addAll(playerConfig.toJson());
    // 调用原生create方法
    final Map<String, dynamic> response = await channel.invokeMapMethod<String, dynamic>(
      'create',
      dataSourceDescription,
    );
    // 将返回的id赋值
    _textureId = response['textureId'];
    // 发送创建完成通知
    _creatingCompleter.complete(null);

    // 初始化完成事件
    final Completer<void> initializingCompleter = Completer<void>();

    // 监听原生发来的消息
    void eventListener(dynamic event) {
      if (_isDisposed) {
        return;
      }
      final Map<dynamic, dynamic> map = event;
      switch (map['event']) {
        case 'initialized':
          value = value.copyWith(
            duration: Duration(milliseconds: map['duration']),
            size: Size(map['width']?.toDouble() ?? 0.0,
                map['height']?.toDouble() ?? 0.0),
          );
          initializingCompleter.complete(null);
          break;
        case 'progress':
          value = value.copyWith(
            position: Duration(milliseconds: map['progress']),
            duration: Duration(milliseconds: map['duration']),
            playable: Duration(milliseconds: map['playable']),
          );
          break;
        case 'loading':
          value = value.copyWith(isLoading: true);
          break;
        case 'loadingend':
          value = value.copyWith(isLoading: false);
          break;
        case 'playend':
          value = value.copyWith(isPlaying: false, position: value.duration);
          break;
        case 'netStatus':
          value = value.copyWith(netSpeed: map['netSpeed']);
          break;
        case 'error':
          value = value.copyWith(errorDescription: map['errorInfo']);
          break;
      }
    }

    _eventSubscription = _eventChannelFor(_textureId).receiveBroadcastStream().listen(eventListener);

    return initializingCompleter.future;
  }

  EventChannel _eventChannelFor(int textureId) {
    return EventChannel('flutter_tencent_video_player/videoEvents$textureId');
  }

  @override
  Future dispose() async {
    if (_creatingCompleter != null) {
      await _creatingCompleter.future;
      if (!_isDisposed) {
        _isDisposed = true;
        await _eventSubscription?.cancel();
        await channel.invokeListMethod('dispose', <String, dynamic>{'textureId': _textureId});
        _lifeCycleObserver.dispose();
      }
    }
    _isDisposed = true;
    super.dispose();
  }

  /// 暂停或播放
  Future<void> _applyPlayPause() async {
    if (!value.initialized || _isDisposed) {
      return;
    }
    if (value.isPlaying) {
      await channel.invokeMethod('play', <String, dynamic>{'textureId': _textureId});
    } else {
      await channel.invokeMethod('pause', <String, dynamic>{'textureId': _textureId});
    }
  }

  /// 播放
  Future<void> play() async {
    value = value.copyWith(isPlaying: true);
    await _applyPlayPause();
  }

  /// 暂停
  Future<void> pause() async {
    value = value.copyWith(isPlaying: false);
    await _applyPlayPause();
  }

  /// 指定位置播放
  Future<void> seekTo(Duration moment) async {
    if (_isDisposed) {
      return;
    }
    if (moment == null) {
      return;
    }
    if (moment > value.duration) {
      moment = value.duration;
    } else if (moment < const Duration()) {
      moment = const Duration();
    }
    await channel.invokeMethod('seekTo', <String, dynamic>{
      'textureId': _textureId,
      'location': moment.inSeconds,
    });
    value = value.copyWith(position: moment);
  }

  ///点播为m3u8子流，会自动无缝seek
  Future<void> setBitrateIndex(int index) async {
    if (_isDisposed) {
      return;
    }
    await channel.invokeMethod('setBitrateIndex', <String, dynamic>{
      'textureId': _textureId,
      'index': index,
    });
    value = value.copyWith(bitrateIndex: index);
  }

  /// 播放速度 快进
  Future<void> setRate(double rate) async {
    if (_isDisposed) {
      return;
    }
    if (rate > 2.0) {
      rate = 2.0;
    } else if (rate < 1.0) {
      rate = 1.0;
    }
    await channel.invokeMethod('setRate', <String, dynamic>{
      'textureId': _textureId,
      'rate': rate,
    });
    value = value.copyWith(rate: rate);
  }

  /// 进入全屏状态
  void enterFullScreen() {
    value = value.copyWith(isFullScreen: true);
    print('enterFullScreen');
  }

  /// 退出全屏状态
  void exitFullScreen() {
    value = value.copyWith(isFullScreen: false);
    print('exitFullScreen');
  }

  /// 切换全屏或非全屏
  void toggleFullScreen() {
    value = value.copyWith(isFullScreen: !value.isFullScreen);
    print('toggleFullScreen');
  }
}

///视频组件生命周期监听
class _VideoAppLifeCycleObserver with WidgetsBindingObserver {
  bool _wasPlayingBeforePause = false;
  final TencentPlayerController _controller;

  _VideoAppLifeCycleObserver(this._controller);

  void initialize() {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        _wasPlayingBeforePause = _controller.value.isPlaying;
        _controller.pause();
        break;
      case AppLifecycleState.resumed:
        if (_wasPlayingBeforePause) {
          _controller.play();
        }
        break;
      default:
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }
}

class TencentPlayerControllerProvider extends InheritedWidget {
  final TencentPlayerController controller;
  TencentPlayerControllerProvider({
    Key key,
    @required this.controller,
    @required Widget child
  }): super(key: key, child: child);

  @override
  bool updateShouldNotify(TencentPlayerControllerProvider old) => controller != old.controller;

}
