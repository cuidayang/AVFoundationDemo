//
//  KYCombinedMediaView.h
//  KYVideoModule
//
//  Created by leoking870 on 2017/12/5.
//

#import <UIKit/UIKit.h>


typedef enum : NSUInteger {
    /**
     * 视频和音乐都不循环
     */
    KYCombinedMediaViewLoopModeNone,
    /**
     * 视频和音乐各自循环
     */
    KYCombinedMediaViewLoopModeSeparate,
    /**
     * 以视频循环为主(视频重播的时候,音乐不管放到哪儿都自动重播)
     */
    KYCombinedMediaViewLoopModeVideoLead,
    /**
     * 以音乐循环为主(音乐重播的时候,视频不管放到哪儿都自动重播)
     */
    KYCombinedMediaViewLoopModeAudioLead,
} KYCombinedMediaViewLoopMode;

@class KYCombinedMediaView;
@protocol KYCombinedMediaViewDelegate <NSObject>
- (void)combinedMediaViewDidLoadMediaSuccess:(KYCombinedMediaView *)combinedMediaView;
- (void)combinedMediaViewDidLoadMediaFail:(KYCombinedMediaView *)combinedMediaView error:(NSError *)error;
- (void)combinedMediaViewDidLoadMedia:(KYCombinedMediaView *)combinedMediaView progress:(CGFloat)progress;


- (void)combinedMediaViewPauseForBuffering:(KYCombinedMediaView *)mediaPlayerView;

- (BOOL)combinedMediaViewShouldAutoPlayStart:(KYCombinedMediaView *)mediaPlayerView;

- (BOOL)combinedMediaViewShouldPlaybackFromBuffering:(KYCombinedMediaView *)mediaPlayerView;

@end




@interface KYCombinedMediaView : UIView
@property (nonatomic, strong) NSURL *videoURL;
@property (nonatomic, strong) NSURL *audioURL;
/**
 * 是否边下边播
 */
@property (nonatomic, assign) IBInspectable BOOL playWhileDownload;

/**
 * 是否使用系统的加载方式
 */
@property (nonatomic, assign)IBInspectable BOOL systemResourceLoader;

/**
 * 缓存几秒之后开始播放, 默认为5s
 */
@property (nonatomic, assign) NSTimeInterval preferredBufferDurationBeforePlayback;
/**
 * 是否缓存够了之后自动播放, 默认为false
 */
@property (nonatomic, assign) IBInspectable BOOL autoplay;
@property (nonatomic, assign) BOOL muted;
/**
 * 循环方式
 */
@property (nonatomic, assign) KYCombinedMediaViewLoopMode loopMode;
@property (nonatomic, weak) id<KYCombinedMediaViewDelegate> delegate;

@property (nonatomic, assign, readonly) NSTimeInterval currentTime;
@property (nonatomic, assign, readonly) NSTimeInterval audioLoaedTime;
@property (nonatomic, assign, readonly) NSTimeInterval videoLoadedTime;


/**
 * 是否准备好了
 */
@property (nonatomic, assign, readonly) BOOL readyForPlay;

- (instancetype)initWithFrame:(CGRect)frame videoURL:(NSURL *)videoURL audioURL:(NSURL*)audioURL;
- (void)startLoad;
- (void)play;
- (void)pause;
- (BOOL)isPlaying;
@end
