//
//  KYVideoMVPreviewAnimatedView.h
//  Pods
//
//  Created by leoking870 on 2017/11/16.
//
//

#import <UIKit/UIKit.h>

@class KYVideoMVPreviewAnimatedView;

@protocol KYVideoMVPreviewAnimatedViewDelegate <NSObject>
/**
 * 有一张图片已经被下载了
 * @param kYVideoMVPreviewAnimatedView
 */
- (void)kYVideoMVPreviewAnimatedViewImageDidLoaded:(KYVideoMVPreviewAnimatedView *)kYVideoMVPreviewAnimatedView;

- (void)kYVideoMVPreviewAnimatedViewImageDidLoadAllImages:(KYVideoMVPreviewAnimatedView *)kYVideoMVPreviewAnimatedView;

- (void)kYVideoMVPreviewAnimatedViewImageDidLoadFailed:(KYVideoMVPreviewAnimatedView *)kYVideoMVPreviewAnimatedView error:(NSError *)error;

- (void)kYVideoMVPreviewAnimatedView:(KYVideoMVPreviewAnimatedView *)kYVideoMVPreviewAnimatedView loadProgress:(CGFloat)progress;
@end


typedef enum : NSUInteger {
    KYVideoMVPreviewAnimatedViewStateNone = 1,
    KYVideoMVPreviewAnimatedViewStateLoading = 1 << 1,
    KYVideoMVPreviewAnimatedViewStateError = 1 << 2,
    KYVideoMVPreviewAnimatedViewStateReadyToPlay = 1 << 3,
    KYVideoMVPreviewAnimatedViewStatePlaying = 1 << 4,
    KYVideoMVPreviewAnimatedViewStatePausing = 1 << 5,
    KYVideoMVPreviewAnimatedViewStateNoMediaData = 1 << 6,
} KYVideoMVPreviewAnimatedViewState;

/**
 * 音乐相册动画view
 * 给定一组图片链接, 该view会以不同的动画和固定的间隔切换各个图片
 */
@interface KYVideoMVPreviewAnimatedView : UIView
/**
 * 图片链接地址
 */
@property(nonatomic, strong) NSArray<NSURL *> *imageURLs;

/**
 * 使用本地图片image
 */
@property(nonatomic, strong) NSArray<UIImage *> *images;
/**
 * 占位图片, 默认为空
 */
@property(nonatomic, strong) UIImage *placeholderImage;
/**
 * 每张图展示的时间, 默认为3.8
 */
@property(nonatomic, assign) CGFloat displayDuration;

@property(nonatomic, assign) CGFloat transitionDuration;
/**
 * 是否正在播放
 */
@property(nonatomic, assign, readonly) BOOL playing;


@property(nonatomic, strong) NSError *error;


@property(nonatomic, assign, readonly) CGFloat progress;


@property(nonatomic, assign, readonly) KYVideoMVPreviewAnimatedViewState state;
/**
 * 代理
 */
@property(nonatomic, weak) id <KYVideoMVPreviewAnimatedViewDelegate> delegate;

/**
 * 开始播放
 */
- (void)play;

- (void)pause;

- (void)resume;


- (BOOL)loadSuccess;

- (BOOL)loadFailed;
@end
