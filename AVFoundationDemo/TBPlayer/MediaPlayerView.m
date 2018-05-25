//
//  MediaPlayerView.m
//  AVFoundationDemo
//
//  Created by leoking870 on 2018/5/8.
//  Copyright © 2018年 leoking870. All rights reserved.
//

#import "MediaPlayerView.h"
#import "TBloaderURLConnection.h"
#import "TBVideoRequestTask.h"
#define kScreenHeight ([UIScreen mainScreen].bounds.size.height)
#define kScreenWidth ([UIScreen mainScreen].bounds.size.width)
@import AVFoundation;
@interface MediaPlayerView ()
@property (nonatomic        ) TBPlayerState  state;
@property (nonatomic        ) CGFloat        loadedProgress;//缓冲进度
@property (nonatomic        ) CGFloat        duration;//视频总时间
@property (nonatomic        ) CGFloat        current;//当前播放时间

@property (nonatomic, strong) AVURLAsset     *videoURLAsset;
@property (nonatomic, strong) AVAsset        *videoAsset;

@property (nonatomic, strong) AVPlayer       *player;
@property (nonatomic, strong) AVPlayerItem   *currentPlayerItem;
@property (nonatomic, strong) AVPlayerLayer  *currentPlayerLayer;
@property (nonatomic, strong) NSObject       *playbackTimeObserver;
@property (nonatomic        ) BOOL           isPauseByUser; //是否被用户暂停
@property (nonatomic,       ) BOOL           isLocalVideo; //是否播放本地文件
@property (nonatomic,       ) BOOL           isFinishLoad; //是否下载完毕
@property (nonatomic, strong) TBloaderURLConnection *resouerLoader;
@end


@implementation MediaPlayerView

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static id _sInstance;
    dispatch_once(&onceToken, ^{
        _sInstance = [[self alloc] init];
    });
    
    return _sInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _isPauseByUser = YES;
        _loadedProgress = 0;
        _duration = 0;
        _current  = 0;
        _state = TBPlayerStateStopped;
        _stopWhenAppDidEnterBackground = YES;
    }
    return self;
}


//清空播放器监听属性
- (void)releasePlayer
{
    if (!self.currentPlayerItem) {
        return;
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.currentPlayerItem removeObserver:self forKeyPath:@"status"];
    [self.currentPlayerItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
    [self.currentPlayerItem removeObserver:self forKeyPath:@"playbackBufferEmpty"];
    [self.currentPlayerItem removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
    [self.player removeTimeObserver:self.playbackTimeObserver];
    self.playbackTimeObserver = nil;
    self.currentPlayerItem = nil;
}

- (void)playWithUrl:(NSURL *)url showView:(UIView *)showView
{
    
    [self.player pause];
    [self releasePlayer];
    self.isPauseByUser = NO;
    self.loadedProgress = 0;
    self.duration = 0;
    self.current  = 0;
    
    NSString *str = [url absoluteString];

    if (![str hasPrefix:@"http"]) {
        self.videoAsset  = [AVURLAsset URLAssetWithURL:url options:nil];
        self.currentPlayerItem          = [AVPlayerItem playerItemWithAsset:_videoAsset];
        if (!self.player) {
            self.player = [AVPlayer playerWithPlayerItem:self.currentPlayerItem];
        } else {
            [self.player replaceCurrentItemWithPlayerItem:self.currentPlayerItem];
        }
        self.currentPlayerLayer       = [AVPlayerLayer playerLayerWithPlayer:self.player];
        self.currentPlayerLayer.frame = CGRectMake(0, 44, showView.bounds.size.width, showView.bounds.size.height-44);
        _isLocalVideo = YES;
        
    } else {   //ios7以上采用resourceLoader给播放器补充数据
        
        self.resouerLoader          = [[TBloaderURLConnection alloc] init];
        self.resouerLoader.delegate = self;
        NSURL *playUrl              = [_resouerLoader getSchemeVideoURL:url];
        self.videoURLAsset             = [AVURLAsset URLAssetWithURL:playUrl options:nil];
        [_videoURLAsset.resourceLoader setDelegate:_resouerLoader queue:dispatch_get_main_queue()];
        self.currentPlayerItem          = [AVPlayerItem playerItemWithAsset:_videoURLAsset];
        
        if (!self.player) {
            self.player = [AVPlayer playerWithPlayerItem:self.currentPlayerItem];
        } else {
            [self.player replaceCurrentItemWithPlayerItem:self.currentPlayerItem];
        }
        self.currentPlayerLayer       = [AVPlayerLayer playerLayerWithPlayer:self.player];
        self.currentPlayerLayer.frame = CGRectMake(0, 44, showView.bounds.size.width, showView.bounds.size.height-44);
        _isLocalVideo = NO;
        
    }
    
    [showView.layer addSublayer:self.currentPlayerLayer];
    
    [self.currentPlayerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    [self.currentPlayerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
    [self.currentPlayerItem addObserver:self forKeyPath:@"playbackBufferEmpty" options:NSKeyValueObservingOptionNew context:nil];
    [self.currentPlayerItem addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackground) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterPlayGround) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemDidPlayToEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:self.currentPlayerItem];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemPlaybackStalled:) name:AVPlayerItemPlaybackStalledNotification object:self.currentPlayerItem];
    
    
    // 本地文件不设置TBPlayerStateBuffering状态
    if ([url.scheme isEqualToString:@"file"]) {
        
        // 如果已经在TBPlayerStatePlaying，则直接发通知，否则设置状态
        if (self.state == TBPlayerStatePlaying) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"kTBPlayerStateChangedNotification" object:nil];
        } else {
            self.state = TBPlayerStatePlaying;
        }
        
    } else {
        
        // 如果已经在TBPlayerStateBuffering，则直接发通知，否则设置状态
        if (self.state == TBPlayerStateBuffering) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"kTBPlayerStateChangedNotification" object:nil];
        } else {
            self.state = TBPlayerStateBuffering;
        }
        
    }
    
    [showView.layer addSublayer:self.currentPlayerLayer];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"kTBPlayerProgressChangedNotification" object:nil];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(halfScreen)];
    
    [showView addGestureRecognizer:tap];
}



- (void)seekToTime:(CGFloat)seconds
{
    if (self.state == TBPlayerStateStopped) {
        return;
    }
    
    seconds = MAX(0, seconds);
    seconds = MIN(seconds, self.duration);
    
    [self.player pause];
    [self.player seekToTime:CMTimeMakeWithSeconds(seconds, NSEC_PER_SEC) completionHandler:^(BOOL finished) {
        self.isPauseByUser = NO;
        [self.player play];
        if (!self.currentPlayerItem.isPlaybackLikelyToKeepUp) {
            self.state = TBPlayerStateBuffering;
            NSLog(@"加载中...");
        }
        
    }];
}

- (void)resumeOrPause
{
    if (!self.currentPlayerItem) {
        return;
    }
    if (self.state == TBPlayerStatePlaying) {
        
        [self.player pause];
        self.state = TBPlayerStatePause;
    } else if (self.state == TBPlayerStatePause) {
        
        [self.player play];
        self.state = TBPlayerStatePlaying;
    }
    self.isPauseByUser = YES;
}

- (void)resume
{
    if (!self.currentPlayerItem) {
        return;
    }
    self.isPauseByUser = NO;
    [self.player play];
}

- (void)pause
{
    if (!self.currentPlayerItem) {
        return;
    }
    self.isPauseByUser = YES;
    self.state = TBPlayerStatePause;
    [self.player pause];
}

- (void)stop
{
    self.isPauseByUser = YES;
    self.loadedProgress = 0;
    self.duration = 0;
    self.current  = 0;
    self.state = TBPlayerStateStopped;
    [self.player pause];
    [self releasePlayer];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"kTBPlayerProgressChangedNotification" object:nil];
}


- (CGFloat)progress
{
    if (self.duration > 0) {
        return self.current / self.duration;
    }
    
    return 0;
}


#pragma mark - observer

- (void)appDidEnterBackground
{
    if (self.stopWhenAppDidEnterBackground) {
        [self pause];
        self.state = TBPlayerStatePause;
        self.isPauseByUser = NO;
    }
}
- (void)appDidEnterPlayGround
{
    if (!self.isPauseByUser) {
        [self resume];
        self.state = TBPlayerStatePlaying;
    }
}

- (void)playerItemDidPlayToEnd:(NSNotification *)notification
{
    [self stop];
}

//在监听播放器状态中处理比较准确
- (void)playerItemPlaybackStalled:(NSNotification *)notification
{
    // 这里网络不好的时候，就会进入，不做处理，会在playbackBufferEmpty里面缓存之后重新播放
    NSLog(@"buffing-----buffing");
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    AVPlayerItem *playerItem = (AVPlayerItem *)object;
    
    if ([keyPath isEqualToString:@"status"]) {
        if ([playerItem status] == AVPlayerStatusReadyToPlay) {
            [self monitoringPlayback:playerItem];// 给播放器添加计时器
            
        } else if ([playerItem status] == AVPlayerStatusFailed || [playerItem status] == AVPlayerStatusUnknown) {
            [self stop];
        }
        
    } else if ([keyPath isEqualToString:@"loadedTimeRanges"]) {  //监听播放器的下载进度
        
        [self calculateDownloadProgress:playerItem];
        
    } else if ([keyPath isEqualToString:@"playbackBufferEmpty"]) { //监听播放器在缓冲数据的状态
        NSLog(@"加载中...");
        
        if (playerItem.isPlaybackBufferEmpty) {
            self.state = TBPlayerStateBuffering;
            [self bufferingSomeSecond];
        }
    }
}

- (void)monitoringPlayback:(AVPlayerItem *)playerItem
{
    
    
    self.duration = playerItem.duration.value / playerItem.duration.timescale; //视频总时间
    [self.player play];
    
    
    __weak __typeof(self)weakSelf = self;
    self.playbackTimeObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 1) queue:NULL usingBlock:^(CMTime time) {
        
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        CGFloat current = playerItem.currentTime.value/playerItem.currentTime.timescale;
        
        if (strongSelf.isPauseByUser == NO) {
            strongSelf.state = TBPlayerStatePlaying;
        }
        
        // 不相等的时候才更新，并发通知，否则seek时会继续跳动
        if (strongSelf.current != current) {
            strongSelf.current = current;
            if (strongSelf.current > strongSelf.duration) {
                strongSelf.duration = strongSelf.current;
            }
            [[NSNotificationCenter defaultCenter] postNotificationName:@"kTBPlayerProgressChangedNotification" object:nil];
        }
        
    }];
    
}

- (void)calculateDownloadProgress:(AVPlayerItem *)playerItem
{
    NSArray *loadedTimeRanges = [playerItem loadedTimeRanges];
    CMTimeRange timeRange = [loadedTimeRanges.firstObject CMTimeRangeValue];// 获取缓冲区域
    float startSeconds = CMTimeGetSeconds(timeRange.start);
    float durationSeconds = CMTimeGetSeconds(timeRange.duration);
    NSTimeInterval timeInterval = startSeconds + durationSeconds;// 计算缓冲总进度
    CMTime duration = playerItem.duration;
    CGFloat totalDuration = CMTimeGetSeconds(duration);
    self.loadedProgress = timeInterval / totalDuration;
    NSLog(@"progress:%f", self.loadedProgress);
    
}
- (void)bufferingSomeSecond
{
    // playbackBufferEmpty会反复进入，因此在bufferingOneSecond延时播放执行完之前再调用bufferingSomeSecond都忽略
    static BOOL isBuffering = NO;
    if (isBuffering) {
        return;
    }
    isBuffering = YES;
    
    // 需要先暂停一小会之后再播放，否则网络状况不好的时候时间在走，声音播放不出来
    [self.player pause];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        // 如果此时用户已经暂停了，则不再需要开启播放了
        if (self.isPauseByUser) {
            isBuffering = NO;
            return;
        }
        
        [self.player play];
        // 如果执行了play还是没有播放则说明还没有缓存好，则再次缓存一段时间
        isBuffering = NO;
        if (!self.currentPlayerItem.isPlaybackLikelyToKeepUp) {
            [self bufferingSomeSecond];
        }
    });
}

- (void)setLoadedProgress:(CGFloat)loadedProgress
{
    if (_loadedProgress == loadedProgress) {
        return;
    }
    
    _loadedProgress = loadedProgress;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"kTBPlayerLoadProgressChangedNotification" object:nil];
}

- (void)setState:(TBPlayerState)state
{
    if (state != TBPlayerStateBuffering) {
        //[[XCHudHelper sharedInstance] hideHud];
    }
    
    if (_state == state) {
        return;
    }
    
    _state = state;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"kTBPlayerStateChangedNotification" object:nil];
    
}


#pragma mark - TBloaderURLConnectionDelegate

- (void)didFinishLoadingWithTask:(TBVideoRequestTask *)task
{
    _isFinishLoad = task.isFinishLoad;
}

//网络中断：-1005
//无网络连接：-1009
//请求超时：-1001
//服务器内部错误：-1004
//找不到服务器：-1003
- (void)didFailLoadingWithTask:(TBVideoRequestTask *)task WithError:(NSInteger)errorCode
{
    NSString *str = nil;
    switch (errorCode) {
        case -1001:
            str = @"请求超时";
            break;
        case -1003:
        case -1004:
            str = @"服务器错误";
            break;
        case -1005:
            str = @"网络中断";
            break;
        case -1009:
            str = @"无网络连接";
            break;
            
        default:
            str = [NSString stringWithFormat:@"%@", @"(_errorCode)"];
            break;
    }
    NSLog(@"str");
}

- (void)dealloc
{
    [self releasePlayer];
}



@end
