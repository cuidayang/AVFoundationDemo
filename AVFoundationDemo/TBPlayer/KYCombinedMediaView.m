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

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
//        _backgroundVideoPlayer = [[KYMediaPlayerView alloc] initWithFrame:frame];
//        _backgroundVideoPlayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        _videoPlayer = [[KYMediaPlayerView alloc] initWithFrame:frame];
        _audioPlayer = [[KYMediaPlayerView alloc] initWithFrame:frame];
        [self addSubview:_backgroundVideoPlayer];
        [self addSubview:_videoPlayer];
        [self addSubview:_audioPlayer];
        [_videoPlayer mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self);
        }];
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
