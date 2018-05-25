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
@end




@interface KYCombinedMediaView : UIView
@property (nonatomic, strong) NSURL *videoURL;
@property (nonatomic, strong) NSURL *audioURL;
@property (nonatomic, assign) BOOL muted;
/**
 * 循环方式
 */
@property (nonatomic, assign) KYCombinedMediaViewLoopMode loopMode;
@property (nonatomic, weak) id<KYCombinedMediaViewDelegate> delegate;
/**
 * 是否准备好了
 */
@property (nonatomic, assign, readonly) BOOL readyForPlay;

- (instancetype)initWithFrame:(CGRect)frame videoURL:(NSURL *)videoURL audioURL:(NSURL*)audioURL;

- (void)play;
- (void)pause;
- (BOOL)isPlaying;
@end
