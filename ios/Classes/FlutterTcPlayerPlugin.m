#import "FlutterTcPlayerPlugin.h"

#import "FLTVideoPlayer.h"
#import "FLTFrameUpdater.h"

@interface FlutterTcPlayerPlugin ()
    
@property(readonly, nonatomic) NSObject<FlutterTextureRegistry>* registry;
@property(readonly, nonatomic) NSObject<FlutterBinaryMessenger>* messenger;
//@property(readonly, nonatomic) NSMutableDictionary* players;
@property(readonly, nonatomic) NSMutableDictionary* downLoads;
@property(readonly, nonatomic) NSObject<FlutterPluginRegistrar>* registrar;

@end


@implementation FlutterTcPlayerPlugin
    
NSObject<FlutterPluginRegistrar>* mRegistrar;
FLTVideoPlayer* player ;
    
- (instancetype)initWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    self = [super init];
    NSAssert(self, @"super init cannot be nil");
    _registry = [registrar textures];
    _messenger = [registrar messenger];
    _registrar = registrar;
    // _players = [NSMutableDictionary dictionaryWithCapacity:1];
    _downLoads = [NSMutableDictionary dictionaryWithCapacity:1];
    NSLog(@"FLTVideo  initWithRegistrar");
    return self;
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  FlutterMethodChannel* channel = [FlutterMethodChannel
      methodChannelWithName:@"flutter_tc_player"
            binaryMessenger:[registrar messenger]];
  FlutterTcPlayerPlugin* instance = [[FlutterTcPlayerPlugin alloc] initWithRegistrar:registrar];
  [registrar addMethodCallDelegate:instance channel:channel];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    //NSLog(@"FLTVideo  call name   %@",call.method);
    if ([@"init" isEqualToString:call.method]) {
        [self disposeAllPlayers];
        result(nil);
    }else if([@"create" isEqualToString:call.method]){
        NSLog(@"FLTVideo  create");
        [self disposeAllPlayers];
        FLTFrameUpdater* frameUpdater = [[FLTFrameUpdater alloc] initWithRegistry:_registry];
        //        FLTVideoPlayer*
        player= [[FLTVideoPlayer alloc] initWithCall:call frameUpdater:frameUpdater registry:_registry messenger:_messenger];
        if (player) {
            [self onPlayerSetup:player frameUpdater:frameUpdater result:result];
        }
        result(nil);
    }else {
        [self onMethodCall:call result:result];
    }
}

-(void) onMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result{
    
    NSDictionary* argsMap = call.arguments;
    // int64_t textureId = ((NSNumber*)argsMap[@"textureId"]).unsignedIntegerValue;
    if([NSNull null]==argsMap[@"textureId"]) {
        return;
    }
    int64_t textureId = ((NSNumber*)argsMap[@"textureId"]).unsignedIntegerValue;
    //    FLTVideoPlayer* player = _players[@(textureId)];
    
    if([@"play" isEqualToString:call.method]){
        [player resume];
        result(nil);
    }else if([@"pause" isEqualToString:call.method]){
        [player pause];
        result(nil);
    }else if([@"seekTo" isEqualToString:call.method]){
        NSLog(@"跳转到指定位置----------");
        [player seekTo:[[argsMap objectForKey:@"location"] intValue]];
        result(nil);
    }else if([@"setRate" isEqualToString:call.method]){ //播放速率
        NSLog(@"修改播放速率----------");
        float rate = [[argsMap objectForKey:@"rate"] floatValue];
        if (rate<0||rate>2) {
            result(nil);
            return;
        }
        [player setRate:rate];
        result(nil);
        
    }else if([@"setBitrateIndex" isEqualToString:call.method]){
        NSLog(@"修改播放清晰度----------");
        int  index = [[argsMap objectForKey:@"index"] intValue];
        [player setBitrateIndex:index];
        result(nil);
    }else if([@"dispose" isEqualToString:call.method]){
        NSLog(@"FLTVideo  dispose   ----   ");
        [_registry unregisterTexture:textureId];
        // [_players removeObjectForKey:@(textureId)];
        //_players= nil;
        [self disposeAllPlayers];
        result(nil);
    }else{
        result(FlutterMethodNotImplemented);
    }
}


- (void)onPlayerSetup:(FLTVideoPlayer*)player
         frameUpdater:(FLTFrameUpdater*)frameUpdater
               result:(FlutterResult)result {
    //    _players[@(player.textureId)] = player;
    result(@{@"textureId" : @(player.textureId)});
    
}

-(void) disposeAllPlayers{
    NSLog(@"FLTVideo 初始化播放器状态----------");
    // Allow audio playback when the Ring/Silent switch is set to silent
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    if(player){
        [player dispose];
        player = nil;
    }
}

@end
