//
//  KYCombinedMediaView.m
//  KYVideoModule
//
//  Created by leoking870 on 2017/12/5.
//

#import "KYCombinedMediaView.h"
#import "KYMediaPlayerView.h"

@interface KYCombinedMediaView () <KYMediaPlayerViewDelegate>
@property(nonatomic, strong) KYMediaPlayerView *videoPlayer;
@property(nonatomic, strong) KYMediaPlayerView *audioPlayer;
@property(nonatomic, strong) KYMediaPlayerView *backgroundVideoPlayer;
@end

@implementation KYCombinedMediaView
- (void)dealloc {
    NSLog(@"KYCombinedMediaView 释放");
}

- (void)setMuted:(BOOL)muted {
    _muted = muted;
    _videoPlayer.muted = muted;
    _audioPlayer.muted = muted;
}

- (void)initialize {
    self.backgroundColor = [UIColor clearColor];
    _videoPlayer = [[KYMediaPlayerView alloc] initWithFrame:CGRectZero];
    _videoPlayer.muted = YES;
    _audioPlayer = [[KYMediaPlayerView alloc] initWithFrame:CGRectZero];
    [self addSubview:_backgroundVideoPlayer];
    [self addSubview:_videoPlayer];
    [self addSubview:_audioPlayer];
    _videoPlayer.translatesAutoresizingMaskIntoConstraints = NO;
    
    NSLayoutConstraint *leading = [_videoPlayer.leadingAnchor constraintEqualToAnchor:self.leadingAnchor];
    NSLayoutConstraint *top = [_videoPlayer.topAnchor constraintEqualToAnchor:self.topAnchor];
    NSLayoutConstraint *trailing = [_videoPlayer.trailingAnchor constraintEqualToAnchor:self.trailingAnchor];
    NSLayoutConstraint *bottom = [_videoPlayer.bottomAnchor constraintEqualToAnchor:self.bottomAnchor];
    [NSLayoutConstraint activateConstraints:@[leading,top, trailing, bottom]];
    
    _videoPlayer.delegate = self;
    _audioPlayer.delegate = self;
    
    //        UIVisualEffectView *effectView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleLight]];
    //        effectView.frame = _backgroundVideoPlayer.bounds;
    //        [_backgroundVideoPlayer addSubview:effectView];
    //        [_backgroundVideoPlayer mas_makeConstraints:^(MASConstraintMaker *make) {
    //            make.edges.equalTo(self);
    //        }];
    //        [effectView mas_makeConstraints:^(MASConstraintMaker *make) {
    //            make.edges.equalTo(_backgroundVideoPlayer);
    //        }];
    //        _backgroundVideoPlayer.hidden = YES;
    //        _backgroundVideoPlayer.muted = YES;
}

-(instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    [self initialize];
    return self;
}

- (void)setPlayWhileDownload:(BOOL)playWhileDownload {
    _playWhileDownload = playWhileDownload;
    self.videoPlayer.playWhileDownload = playWhileDownload;
    self.audioPlayer.playWhileDownload = playWhileDownload;
}

- (void)setAutoplay:(BOOL)autoplay {
    _autoplay = autoplay;
    self.videoPlayer.autoplay = autoplay;
    self.audioPlayer.autoplay = autoplay;
}

- (void)setSystemResourceLoader:(BOOL)systemResourceLoader {
    _systemResourceLoader = systemResourceLoader;
    self.videoPlayer.systemResourceLoader = systemResourceLoader;
    self.audioPlayer.systemResourceLoader = systemResourceLoader;
}

- (void)setPreferredBufferDurationBeforePlayback:(NSTimeInterval)preferredBufferDurationBeforePlayback {
    _preferredBufferDurationBeforePlayback = preferredBufferDurationBeforePlayback;
    self.videoPlayer.preferredBufferDurationBeforePlayback = preferredBufferDurationBeforePlayback;
    self.audioPlayer.preferredBufferDurationBeforePlayback = preferredBufferDurationBeforePlayback;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self initialize];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame videoURL:(NSURL *)videoURL audioURL:(NSURL *)audioURL {
    self = [self initWithFrame:frame];
    if (self) {
        _videoPlayer.mediaURL = videoURL;
        _audioPlayer.mediaURL = audioURL;
        _backgroundVideoPlayer.mediaURL = videoURL;
    }
    return self;
}

- (void)startLoad {
    [self.videoPlayer startLoad];
    [self.audioPlayer startLoad];
}

- (BOOL)readyForPlay {
    //视频必须是好的, 音乐必须加载完毕(不管成功还是失败)
    return [self.videoPlayer loadSuccess] && [self.audioPlayer loadFinished];
}

- (void)setVideoURL:(NSURL *)videoURL {
    _videoURL = videoURL;
    _videoPlayer.mediaURL = videoURL;
    _backgroundVideoPlayer.mediaURL = videoURL;
}

- (void)setAudioURL:(NSURL *)audioURL {
    _audioURL = audioURL;
    _audioPlayer.mediaURL = audioURL;
}

- (void)setLoopMode:(KYCombinedMediaViewLoopMode)loopMode {
    _loopMode = loopMode;
    if (loopMode == KYCombinedMediaViewLoopModeNone) {
        _videoPlayer.loopPlayback = NO;
        _audioPlayer.loopPlayback = NO;
        _backgroundVideoPlayer.loopPlayback = NO;
    }
    else {
        _videoPlayer.loopPlayback = YES;
        _audioPlayer.loopPlayback = YES;
        _backgroundVideoPlayer.loopPlayback = YES;
    }
}

- (void)mediaPlayerDidReachToEnd:(KYMediaPlayerView *)mediaPlayerView {
    if (_loopMode == KYCombinedMediaViewLoopModeVideoLead && mediaPlayerView == _videoPlayer) {
        if (![self.videoPlayer containAudioTrack]) {
            [_audioPlayer replay];
        }
    }
    if (_loopMode == KYCombinedMediaViewLoopModeAudioLead && mediaPlayerView == _audioPlayer) {
        [_videoPlayer replay];
        [_backgroundVideoPlayer replay];
    }
}

- (void)play {
    [self.videoPlayer play];
    if (![self.videoPlayer containAudioTrack]) {
        [self.audioPlayer play];
    }

    if (self.backgroundVideoPlayer.hidden) {
        self.backgroundVideoPlayer.hidden = NO;
    }
    [self.backgroundVideoPlayer play];
}

- (void)pause {
    [self.videoPlayer pause];
    if (![self.videoPlayer containAudioTrack]) {
        [self.audioPlayer pause];
    }
    [self.backgroundVideoPlayer pause];
}


- (void)mediaPlayerViewPauseForBuffering:(KYMediaPlayerView *)mediaPlayerView {
    [self.audioPlayer pauseForBufferring];
    [self.videoPlayer pauseForBufferring];
    if ([self.delegate respondsToSelector:@selector(combinedMediaViewPauseForBuffering:)]) {
        [self.delegate combinedMediaViewPauseForBuffering:self];
    }
}
- (BOOL)mediaPlayerViewShouldPlaybackFromBuffering:(KYMediaPlayerView *)mediaPlayerView {
    if (self.audioPlayer.isBufferDurationReached && [self.videoPlayer isBufferDurationReached]) {
        if ([self.delegate respondsToSelector:@selector(combinedMediaViewShouldPlaybackFromBuffering:)]) {
            if ([self.delegate combinedMediaViewShouldPlaybackFromBuffering:self]) {
                [self.audioPlayer playFromBuffering];
                [self.videoPlayer playFromBuffering];
            }
        }
        else {
            [self.audioPlayer playFromBuffering];
            [self.videoPlayer playFromBuffering];
        }
    }
    return NO;
}
- (BOOL)mediaPlayerViewShouldAutoPlayStart:(KYMediaPlayerView *)mediaPlayerView {
    if (self.audioPlayer.isBufferDurationReached && (self.videoPlayer.loadedTime > (self.videoPlayer.currentTime+_preferredBufferDurationBeforePlayback))) {
        if ([self.delegate respondsToSelector:@selector(combinedMediaViewShouldAutoPlayStart:)]) {
            if ([self.delegate combinedMediaViewShouldAutoPlayStart:self]) {
                [self.audioPlayer play];
                [self.videoPlayer play];
            }
        }
        else {
            [self.audioPlayer play];
            [self.videoPlayer play];
        }
    }
    return NO;
}

- (void)mediaPlayerViewDidLoadMediaSuccess:(KYMediaPlayerView *)mediaPlayerView {
    /**
     * 只要视频加载成功就算成功,音乐有就放,没有就不放
     */
    if ([self.videoPlayer loadSuccess] && [self.audioPlayer loadFinished]) {
        if ([self.delegate respondsToSelector:@selector(combinedMediaViewDidLoadMediaSuccess:)]) {
            [self.delegate combinedMediaViewDidLoadMediaSuccess:self];
        }
    }
}

- (void)mediaPlayerViewDidLoadMediaFail:(KYMediaPlayerView *)mediaPlayerView error:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.videoPlayer loadFinished] && [self.audioPlayer loadFinished]) {
            if ([self.videoPlayer loadSuccess]) {
                if ([self.delegate respondsToSelector:@selector(combinedMediaViewDidLoadMediaSuccess:)]) {
                    [self.delegate combinedMediaViewDidLoadMediaSuccess:self];
                }
            } else {
                if ([self.delegate respondsToSelector:@selector(combinedMediaViewDidLoadMediaFail:error:)]) {
                    [self.delegate combinedMediaViewDidLoadMediaFail:self error:error];
                }
            }
        }
    });
}

- (void)mediaPlayerViewDidLoadMedia:(KYMediaPlayerView *)mediaPlayerView progress:(CGFloat)progress {
    if ([self.delegate respondsToSelector:@selector(combinedMediaViewDidLoadMedia:progress:)]) {
        [self.delegate combinedMediaViewDidLoadMedia:self progress:(self.audioPlayer.progress + self.videoPlayer.progress) / 2];
    }
}

- (NSTimeInterval)currentTime {
    return [self.videoPlayer currentTime];
}

- (NSTimeInterval)videoLoadedTime {
    return self.videoPlayer.loadedTime;
}

- (NSTimeInterval)audioLoaedTime {
    return self.audioPlayer.loadedTime;
}

- (BOOL)isPlaying {
    if (self.videoPlayer.mediaURL) {
        return self.videoPlayer.playing;
    }
    if (self.audioPlayer.mediaURL) {
        return self.audioPlayer.playing;
    }
    return NO;
}
@end
