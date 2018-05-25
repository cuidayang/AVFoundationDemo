//
//  KYMediaPlayerView.h
//  KYVideoModule
//
//  Created by leoking870 on 2017/12/5.
//

#import <UIKit/UIKit.h>

@import AVFoundation;
@class KYMediaPlayerView;
@protocol KYMediaPlayerViewDelegate <NSObject>
//加载成功
- (void)mediaPlayerViewDidLoadMediaSuccess:(KYMediaPlayerView *)mediaPlayerView;
//加载失败
- (void)mediaPlayerViewDidLoadMediaFail:(KYMediaPlayerView *)mediaPlayerView error:(NSError *)error;
//加载过程
- (void)mediaPlayerViewDidLoadMedia:(KYMediaPlayerView *)mediaPlayerView progress:(CGFloat)progress;
/**
 * 播放结束
 */

- (void)mediaPlayerDidReachToEnd:(KYMediaPlayerView *)mediaPlayerView;
- (void)mediaPlayerViewPauseForBuffering:(KYMediaPlayerView *)mediaPlayerView;
- (BOOL)mediaPlayerViewShouldPlaybackFromBuffering:(KYMediaPlayerView *)mediaPlayerView;
- (BOOL)mediaPlayerViewShouldAutoPlayStart:(KYMediaPlayerView *)mediaPlayerView;
@end

typedef enum : NSUInteger {
    KYMediaPlayerViewStateNone = 1,
    KYMediaPlayerViewStateLoading = 1 << 1,
    KYMediaPlayerViewStateError = 1 << 2,
    KYMediaPlayerViewStateReadyToPlay  = 1 << 3,
    KYMediaPlayerViewStatePlaying = 1 << 4,
    KYMediaPlayerViewStateBuffering = 1 << 5,
    KYMediaPlayerViewStatePausing =  1 << 6,
    KYMediaPlayerViewStateNoMediaData = 1 << 7
} KYMediaPlayerViewState;

IB_DESIGNABLE
@interface KYMediaPlayerView : UIView

@property(nonatomic, strong, readonly) AVPlayer *avPlayer;

/**
 * 媒体地址
 */
@property (nonatomic, strong) NSURL *mediaURL;


@property (nonatomic, weak) id<KYMediaPlayerViewDelegate> delegate;
/**
 * 下载到本地之后的地址
 */
@property (nonatomic, strong, readonly) NSURL *localURL;
/**
 * 是否正在播放
 */
@property (nonatomic, assign, readonly) BOOL playing;
/**
 * 是否准备好了可以播放
 */
@property (nonatomic, assign, readonly) BOOL readyForPlay;
/**
 * 当前状态
 */
@property (nonatomic, assign, readonly) KYMediaPlayerViewState state;
/**
 * 当前加载进度
 */
@property (nonatomic, assign, readonly) CGFloat progress;
/**
 * 视频在view上的填充方式
 */
@property (nonatomic, assign) AVLayerVideoGravity videoGravity;
/**
 * 当发生错误时表示错误
 */
@property (nonatomic, strong) NSError *error;

/**
 * 是否包含音轨
 */
@property (nonatomic, assign, readonly) BOOL containAudioTrack;
/**
 * 静音
 */
@property (nonatomic, assign) IBInspectable BOOL muted;
/**
 * 是否缓存够了之后自动播放, 默认为false
 */
@property (nonatomic, assign) IBInspectable BOOL autoplay;
/**
 * 是否边下边播
 */
@property (nonatomic, assign) IBInspectable BOOL playWhileDownload;
/**
 * 是否自动循环播放
 */
@property (nonatomic, assign) IBInspectable BOOL loopPlayback;

- (instancetype)initWithFrame:(CGRect)frame mediaURL:(NSURL*)mediaURL;

- (void)startLoad;
- (void)startLoadWithPlayerItem:(AVPlayerItem *)item;
- (void)play;
- (void)pause;
/**
 * 暂停, 当缓存够了自动重新播放( 不影响当前state)
 */
- (void)pauseForBufferring;
/**
 * 播放(不影响当前state)
 */
- (void)playFromBuffering;
- (void)seekToTime:(NSTimeInterval)time;
/*
 * 重头开始播放
 */
- (void)replay;
/**
 * 是否完成加载(不管是成功还是失败,还是没有资源)
 * @return YES:加载完成, NO:还在加载
 */
- (BOOL)loadFinished;
- (BOOL)loadSuccess;
- (BOOL)loadFailed;

/**
 * 是否使用系统的加载方式
 */
@property (nonatomic, assign)IBInspectable BOOL systemResourceLoader;
/**
 * 缓存几秒之后开始播放, 默认为3s (当systemResourceLoader为YES时不起作用)
 */
@property (nonatomic, assign) NSTimeInterval preferredBufferDurationBeforePlayback;

/**
 * 是否达到缓存目标
 */
@property (nonatomic, assign) BOOL isBufferDurationReached;

@property (nonatomic, readonly) CGFloat loadedTime;

@property (nonatomic, readonly) CGFloat currentTime;

@property (nonatomic, readonly) NSTimeInterval preferredForwardBufferDuration;

@property (nonatomic, readonly) AVPlayerTimeControlStatus timeControlStatus;

@property (nonatomic, readonly, getter=isPlaybackLikelyToKeepUp) BOOL playbackLikelyToKeepUp;

@property (nonatomic, readonly, getter=isPlaybackBufferFull) BOOL playbackBufferFull;

@property (nonatomic, readonly, getter=isPlaybackBufferEmpty) BOOL playbackBufferEmpty;

@end
