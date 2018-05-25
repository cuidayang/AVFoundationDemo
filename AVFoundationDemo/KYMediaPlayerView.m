//
//  KYMediaPlayerView.m
//  KYVideoModule
//
//  Created by leoking870 on 2017/12/5.
//

#import "KYMediaPlayerView.h"
#import "KYMediaDownloadManager.h"
#import "KYAVPlayerResourceLoader.h"
@import AVFoundation;

@interface KYMediaPlayerView ()
@property(nonatomic, strong, readwrite) AVPlayer *avPlayer;
@property(nonatomic, assign) BOOL firstLoaded;
@property(nonatomic, strong, readwrite) NSURL *localURL;
@property(nonatomic, assign) CGFloat progress;
@property(nonatomic, assign) KYMediaPlayerViewState state;
@property(nonatomic, strong) KYMediaDownloadInfo *downloadInfo;
@property (nonatomic, assign, readwrite) BOOL containAudioTrack;
@property (nonatomic, assign) CGFloat pausingTime;
@end

@implementation KYMediaPlayerView
+ (Class)layerClass {
    return [AVPlayerLayer class];
}

- (void)dealloc {
    NSLog(@"KYMediaPlayerView 释放了");
    if ([_avPlayer respondsToSelector:@selector(setAutomaticallyWaitsToMinimizeStalling:)]) {
        [_avPlayer removeObserver:self forKeyPath:@"timeControlStatus"];
    }
    [_avPlayer.currentItem removeObserver:self forKeyPath:@"status"];
    [_avPlayer.currentItem removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
    [_avPlayer.currentItem removeObserver:self forKeyPath:@"playbackBufferEmpty"];
    [_avPlayer.currentItem removeObserver:self forKeyPath:@"playbackBufferFull"];
    [_avPlayer.currentItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:_avPlayer.currentItem];
    if (self.state == KYMediaPlayerViewStateLoading && self.downloadInfo) {
        [[KYMediaDownloadManager sharedInstance] cancleMediaDownload:self.downloadInfo];
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVAudioSessionRouteChangeNotification object:[AVAudioSession sharedInstance]];
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self initialize];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initialize];
    }
    return self;
}

- (void)initialize {
    _state = KYMediaPlayerViewStateNone;
    _firstLoaded = YES;
    _autoplay = NO;
    _playWhileDownload = NO;
    //_autoplayAfterBufferEnough = NO;
    _preferredBufferDurationBeforePlayback = 3;
    _avPlayer = [[AVPlayer alloc] init];
    ((AVPlayerLayer *) (self.layer)).player = _avPlayer;
    ((AVPlayerLayer *) (self.layer)).videoGravity = AVLayerVideoGravityResizeAspect;
    if ([_avPlayer respondsToSelector:@selector(setAutomaticallyWaitsToMinimizeStalling:)]) {
        [_avPlayer setAutomaticallyWaitsToMinimizeStalling:NO];
        [_avPlayer addObserver:self forKeyPath:@"timeControlStatus" options:NSKeyValueObservingOptionNew context:nil];
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(routeChange:) name:AVAudioSessionRouteChangeNotification object:[AVAudioSession sharedInstance]];
    
    CIFilter *filter = [CIFilter filterWithName:@"CIGaussianBlur"];
    [filter setDefaults];
    [filter setValue:@(10) forKey:kCIInputRadiusKey];
    self.layer.filters = @[filter];
}

//-(void)awakeFromNib {
//
//    [self initialize];
//    [super awakeFromNib];
//}

- (void)routeChange:(NSNotification *)notification {
    NSDictionary *dic=notification.userInfo;
    int changeReason= [dic[AVAudioSessionRouteChangeReasonKey] intValue];
    //等于AVAudioSessionRouteChangeReasonOldDeviceUnavailable表示旧输出不可用
    if (changeReason == AVAudioSessionRouteChangeReasonNewDeviceAvailable) {
        if ([AVAudioSession.sharedInstance.currentRoute.outputs.firstObject.portType isEqualToString:AVAudioSessionPortHeadphones]) {
            //插入耳机
            NSLog(@"插入耳机");
        }
    }
    else if(changeReason == AVAudioSessionRouteChangeReasonOldDeviceUnavailable){
        AVAudioSessionRouteDescription *previousRoute = dic[AVAudioSessionRouteChangePreviousRouteKey];
        if ([previousRoute.outputs.firstObject.portType isEqualToString:AVAudioSessionPortHeadphones]) {
            NSLog(@"移出耳机");
            [self pause];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.1f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self play];
                });
            });
        }
    }
}

- (void)setVideoGravity:(AVLayerVideoGravity)videoGravity {
    _videoGravity = videoGravity;
    ((AVPlayerLayer *) (self.layer)).videoGravity = videoGravity;
}

- (void)startLoadWithPlayerItem:(AVPlayerItem *)item {
    if (_avPlayer.currentItem) {
        [_avPlayer.currentItem removeObserver:self forKeyPath:@"status"];
        [_avPlayer.currentItem removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
        [_avPlayer.currentItem removeObserver:self forKeyPath:@"playbackBufferEmpty"];
        [_avPlayer.currentItem removeObserver:self forKeyPath:@"playbackBufferFull"];
        [_avPlayer.currentItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:_avPlayer.currentItem];
    }
    [_avPlayer replaceCurrentItemWithPlayerItem:item];
    [self addObserverForCurrentItem];
    self.state = KYMediaPlayerViewStateLoading;
}

- (void)startLoad {
    if (_mediaURL) {
        if ([_mediaURL isFileURL] || [_mediaURL.absoluteString hasPrefix:@"ipod-library"]) {
            self.state = KYMediaPlayerViewStateLoading;
            self.localURL = _mediaURL;
            [self setPlayerURL:self.localURL];
        } else {
            __weak KYMediaPlayerView *wself = self;
            if (_playWhileDownload) {
                //边下边播
                [self setPlayerURL:_mediaURL];
            }
            else {
                self.downloadInfo = [[KYMediaDownloadManager sharedInstance] downloadMediaWithURL:_mediaURL progress:^(CGFloat progress) {
                    wself.progress = progress;
                    if ([wself.delegate respondsToSelector:@selector(mediaPlayerViewDidLoadMedia:progress:)]) {
                        [wself.delegate mediaPlayerViewDidLoadMedia:wself progress:wself.progress];
                    }
                }                                                                      completion:^(NSURL *filePathURL, NSError *error) {
                    if (filePathURL) {
                        wself.localURL = filePathURL;
                        [wself setPlayerURL:wself.localURL];
                    } else {
                        wself.state = KYMediaPlayerViewStateError;
                        wself.error = error;
                        if ([wself.delegate respondsToSelector:@selector(mediaPlayerViewDidLoadMediaFail:error:)]) {
                            [wself.delegate mediaPlayerViewDidLoadMediaFail:wself error:error];
                        }
                    }
                }];
            }
            self.state = KYMediaPlayerViewStateLoading;
        }
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.state = KYMediaPlayerViewStateNoMediaData;
            if ([self.delegate respondsToSelector:@selector(mediaPlayerViewDidLoadMediaFail:error:)]) {
                [self.delegate mediaPlayerViewDidLoadMediaFail:self error:nil];
            }
        });
    }
}

- (void)setPlayerURL:(NSURL *)playerURL {
    if (_avPlayer.currentItem) {
        [_avPlayer.currentItem removeObserver:self forKeyPath:@"status"];
        [_avPlayer.currentItem removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
        [_avPlayer.currentItem removeObserver:self forKeyPath:@"playbackBufferEmpty"];
        [_avPlayer.currentItem removeObserver:self forKeyPath:@"playbackBufferFull"];
        [_avPlayer.currentItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:_avPlayer.currentItem];
    }
    if (_playWhileDownload) {
        if (self.systemResourceLoader) {
            AVPlayerItem *item = [AVPlayerItem playerItemWithURL:playerURL];
            _avPlayer.automaticallyWaitsToMinimizeStalling = YES;
            [_avPlayer replaceCurrentItemWithPlayerItem:item];
        }
        else {
            AVPlayerItem *item = [AVPlayerItem playerItemWithKYResourceURL:playerURL diskCacheDirectory:nil];
            _avPlayer.automaticallyWaitsToMinimizeStalling = NO;
            [_avPlayer replaceCurrentItemWithPlayerItem:item];
        }
    }
    else {
        AVPlayerItem *item = [AVPlayerItem playerItemWithURL:playerURL];
        [_avPlayer replaceCurrentItemWithPlayerItem:item];
    }
    [self addObserverForCurrentItem];
}

- (void)addObserverForCurrentItem {
    if (_avPlayer.currentItem) {
        [_avPlayer.currentItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
        [_avPlayer.currentItem addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:nil];
        [_avPlayer.currentItem addObserver:self forKeyPath:@"playbackBufferEmpty" options:NSKeyValueObservingOptionNew context:nil];
        [_avPlayer.currentItem addObserver:self forKeyPath:@"playbackBufferFull" options:NSKeyValueObservingOptionNew context:nil];
        [_avPlayer.currentItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(videoPlayToEnd:)
                                                     name:AVPlayerItemDidPlayToEndTimeNotification
                                                   object:_avPlayer.currentItem];//NOTE: 这里的object必须是item,而不能是player本身,不然接受不到通知
    }
}

- (BOOL)playing {
    return self.avPlayer.rate != 0;
}

- (BOOL)readyForPlay {
    return self.avPlayer.currentItem.status == AVPlayerItemStatusReadyToPlay;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey, id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"status"]) {
        NSNumber *value = change[NSKeyValueChangeNewKey];
        if (value.integerValue == AVPlayerItemStatusReadyToPlay) {
            if (_state == KYMediaPlayerViewStateLoading) {
                _state = KYMediaPlayerViewStateReadyToPlay;
            }
            NSArray *tracks = [self.avPlayer.currentItem.asset tracksWithMediaType:AVMediaTypeAudio];
            self.containAudioTrack = tracks.count > 0;
            if (self.containAudioTrack) {
                self.avPlayer.muted = self.muted;
            }
            if ([self.delegate respondsToSelector:@selector(mediaPlayerViewDidLoadMediaSuccess:)]) {
                [self.delegate mediaPlayerViewDidLoadMediaSuccess:self];
            }
            //可能资源已经加载完毕了
            if (self.avPlayer.automaticallyWaitsToMinimizeStalling) {
                if (self.autoplay) {
                    [self play];
                }
            }
            else {
                [self autoPlayWhenBufferIsReached];
            }
            NSLog(@"媒体文件:%@, 加载成功", self.mediaURL);
        } else if (value.integerValue == AVPlayerItemStatusFailed) {
            self.state = KYMediaPlayerViewStateError;
            self.error = self.avPlayer.currentItem.error;
            if ([self.delegate respondsToSelector:@selector(mediaPlayerViewDidLoadMediaFail:error:)]) {
                [self.delegate mediaPlayerViewDidLoadMediaFail:self error:self.avPlayer.currentItem.error];
            }
            NSLog(@"媒体文件:%@, error:%@", self.mediaURL, self.avPlayer.currentItem.error);
        }
    } else if ([keyPath isEqualToString:@"playbackLikelyToKeepUp"]) {
        
    } else if ([keyPath isEqualToString:@"playbackBufferEmpty"]) {
        NSNumber *value = change[NSKeyValueChangeNewKey];
        if (value.boolValue) {
            NSLog(@"缓冲池空了");
            if (!self.avPlayer.automaticallyWaitsToMinimizeStalling) {
                if ([self.delegate respondsToSelector:@selector(mediaPlayerViewPauseForBuffering:)]) {
                    [self.delegate mediaPlayerViewPauseForBuffering:self];
                }
            }
        } else {
            NSLog(@"缓冲池有数据");
        }
    } else if ([keyPath isEqualToString:@"playbackBufferFull"]) {
        NSNumber *value = change[NSKeyValueChangeNewKey];
        if (value.boolValue) {
            NSLog(@"缓冲池满了");
        }
    } else if ([keyPath isEqualToString:@"timeControlStatus"]) {
        NSNumber *value = change[NSKeyValueChangeNewKey];
        if (value.integerValue == AVPlayerTimeControlStatusPlaying) {
            if ([self.delegate respondsToSelector:@selector(mediaPlayerViewShouldPlaybackFromBuffering:)]) {
                [self.delegate mediaPlayerViewShouldPlaybackFromBuffering:self];
            }
        } else if (value.integerValue == AVPlayerTimeControlStatusPaused) {
        }
        else {
            //waiting
            if ([self.delegate respondsToSelector:@selector(mediaPlayerViewPauseForBuffering:)]) {
                [self.delegate mediaPlayerViewPauseForBuffering:self];
            }
        }
    }
    else if([keyPath isEqualToString:@"loadedTimeRanges"]){
        CGFloat progress = [self loadingPercent];
//        NSLog(@"progress:%f", progress);
        
        //如果automaticallyWaitsToMinimizeStalling为YES, 那么会自动重新启动播放
        if (!self.avPlayer.automaticallyWaitsToMinimizeStalling) {
            [self autoPlayWhenBufferIsReached];
        }
    }
}

- (void)autoPlayWhenBufferIsReached {
    if (self.loadedTime > (self.currentTime + self.preferredBufferDurationBeforePlayback)) {
        if (self.avPlayer.rate == 0 && self.state == KYMediaPlayerViewStatePlaying) {
            BOOL should = YES;
            if ([self.delegate respondsToSelector:@selector(mediaPlayerViewShouldPlaybackFromBuffering:)]) {
                should = [self.delegate mediaPlayerViewShouldPlaybackFromBuffering:self];
            }
            if (should) {
                [self.avPlayer playImmediatelyAtRate:1.0];
                NSLog(@"继续播放");
            }
        }
        if (self.state == KYMediaPlayerViewStateReadyToPlay && self.autoplay) {
            BOOL should = YES;
            if ([self.delegate respondsToSelector:@selector(mediaPlayerViewShouldAutoPlayStart:)]) {
                should = [self.delegate mediaPlayerViewShouldAutoPlayStart:self];
                
            }
            if (should) {
                [self play];
                NSLog(@"开始播放");
            }
        }
    }
}

- (void)pauseForBufferring {
    [self.avPlayer setRate:0];
}

- (void)playFromBuffering {
    [self.avPlayer setRate:1.0];
}

- (BOOL)isBufferDurationReached {
    return self.loadedTime > (self.currentTime + self.preferredForwardBufferDuration);
}

- (CGFloat)loadedTime {
    NSArray *loadedTimeRanges = [self.avPlayer.currentItem loadedTimeRanges];
    if (loadedTimeRanges.count) {
        CMTimeRange timeRange = [loadedTimeRanges.firstObject CMTimeRangeValue];// 获取缓冲区域
        float startSeconds = CMTimeGetSeconds(timeRange.start);
        float durationSeconds = CMTimeGetSeconds(timeRange.duration);
        NSTimeInterval timeInterval = startSeconds + durationSeconds;// 计算缓冲总进度
        return timeInterval;
    }
    return 0;
}

- (AVPlayerTimeControlStatus)timeControlStatus {
    return self.avPlayer.timeControlStatus;
}

- (BOOL)isPlaybackBufferFull {
    return self.avPlayer.currentItem.isPlaybackBufferFull;
}
- (BOOL)isPlaybackLikelyToKeepUp {
    return self.avPlayer.currentItem.isPlaybackLikelyToKeepUp;
}
- (BOOL)isPlaybackBufferEmpty {
    return self.avPlayer.currentItem.isPlaybackBufferEmpty;
}

- (CGFloat)currentTime {
    return CMTimeGetSeconds(self.avPlayer.currentTime);
}

- (NSTimeInterval)preferredForwardBufferDuration {
    return self.avPlayer.currentItem.preferredForwardBufferDuration;
}

- (CGFloat)loadingPercent {
    NSArray *loadedTimeRanges = [self.avPlayer.currentItem loadedTimeRanges];
    CMTimeRange timeRange = [loadedTimeRanges.firstObject CMTimeRangeValue];// 获取缓冲区域
    float startSeconds = CMTimeGetSeconds(timeRange.start);
    float durationSeconds = CMTimeGetSeconds(timeRange.duration);
    NSTimeInterval timeInterval = startSeconds + durationSeconds;// 计算缓冲总进度
    CMTime duration = self.avPlayer.currentItem.duration;
    CGFloat totalDuration = CMTimeGetSeconds(duration);
    CGFloat progress = timeInterval / totalDuration;
    return progress;
}

- (void)setMuted:(BOOL)muted {
    _muted = muted;
    if (self.containAudioTrack) {
        self.avPlayer.muted = self.muted;
    }
}

- (void)videoPlayToEnd:(NSNotification *)sender {
    if (sender.object == self.avPlayer.currentItem) {
        if (self.loopPlayback) {
            [self replay];
        }
        if ([self.delegate respondsToSelector:@selector(mediaPlayerDidReachToEnd:)]) {
            [self.delegate mediaPlayerDidReachToEnd:self];
        }
    }
}


- (void)play {
    if (_state == KYMediaPlayerViewStateReadyToPlay || _state == KYMediaPlayerViewStatePausing) {
        [self.avPlayer playImmediatelyAtRate:1.0];
        _state = KYMediaPlayerViewStatePlaying;
    }
}

- (void)pause {
    if (_state == KYMediaPlayerViewStatePlaying) {
        [self.avPlayer pause];
        _state = KYMediaPlayerViewStatePausing;
    }
}

- (void)seekToTime:(NSTimeInterval)time {
    AVPlayerLayer *layer = (AVPlayerLayer *) self.layer;
//    CMTimeScale timeScale = layer.player.currentItem.asset.duration.timescale;
    [self.avPlayer seekToTime:CMTimeMakeWithSeconds(time, 60000)];
}

- (void)replay {
    AVPlayerLayer *layer = (AVPlayerLayer *) self.layer;
    CMTimeScale timeScale = layer.player.currentItem.asset.duration.timescale;
    [layer.player seekToTime:CMTimeMake(0, timeScale)];
    [layer.player play];
}


- (BOOL)loadFinished {
    return self.state != KYMediaPlayerViewStateNone && self.state != KYMediaPlayerViewStateLoading;
}

- (BOOL)loadSuccess {
    return self.state == KYMediaPlayerViewStateReadyToPlay || self.state == KYMediaPlayerViewStatePlaying || self.state == KYMediaPlayerViewStatePausing;
}

- (BOOL)loadFailed {
    return self.state == KYMediaPlayerViewStateError || self.state == KYMediaPlayerViewStateNoMediaData;
}

@end
