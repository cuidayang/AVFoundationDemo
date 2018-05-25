//
//  AVFoundationUtils.h
//  AVFoundationDemo
//
//  Created by leoking870 on 2018/5/15.
//  Copyright © 2018年 leoking870. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
@import Photos;
typedef NS_ENUM(NSInteger, AVFoundationUtilsResizeMode) {
    AVFoundationUtilsResizeModeScaleToFill,
    AVFoundationUtilsResizeModeScaleAspectFit,      // contents scaled to fit with fixed aspect. remainder is transparent
    AVFoundationUtilsResizeModeScaleAspectFill,     // contents scaled to fill with fixed aspect. some portion of content may be clipped.
};

typedef NS_ENUM(NSInteger, AVFoundationBackgroundMode) {
    AVFoundationBackgroundModeBlurFirstFrame,
    AVFoundationBackgroundModeScaleVideoToFill,      // contents scaled to fit with fixed aspect. remainder is transparent
    AVFoundationBackgroundModeBlack,     // contents scaled to fill with fixed aspect. some portion of content may be clipped.
};

@interface AVFoundationUtils : NSObject

+ (void)resizeVideoWithURL:(NSURL *)url
                targetSize:(CGSize)size
                resizeMode:(AVFoundationUtilsResizeMode)resizeMode
                compositions:(void (^)(AVMutableComposition *composition, AVMutableVideoComposition *videoComposition))compositions;


+ (void)resizeVideoWithURL:(NSURL *)url
                targetSize:(CGSize)size
                resizeMode:(AVFoundationUtilsResizeMode)resizeMode
                  progress:(void(^)(CGFloat))progress
                completion:(void (^)(NSURL *, NSError *))completion;


+ (void)gpuBlurVideoWithURL:(NSURL *)url
                    radius:(CGFloat)radius
                    progress:(void(^)(CGFloat))progress
                completion:(void (^)(NSURL *, NSError *))completion;

+ (void)exportComposition:(AVMutableComposition *)composition
         videoComposition:(AVMutableVideoComposition *)videoComposition
                 progress:(void(^)(CGFloat p))progress
               completion:(void(^)(NSURL *url, NSError *))completion;

+ (void)overlayVideo:(NSURL *)videoURL
             onVideo:(NSURL *)backgroundVideoURL
          targetSize:(CGSize)targetSize
            progress:(void(^)(CGFloat))progress
          completion:(void(^)(NSURL *url, NSError *error))completion;


+ (void)overlayVideo:(NSURL *)videoURL
             onVideo:(NSURL *)backgroundVideoURL
          targetSize:(CGSize)targetSize
          compositions:(void (^)(AVMutableComposition *composition, AVMutableVideoComposition *videoComposition))compositions;


+ (void)overlayVideo:(NSURL *)videoURL
            position:(CGPoint)position
                size:(CGSize)size
          aboveVideo:(NSURL *)backgroundVideoURL
      backgroundSize:(CGSize)backgroundSize
        compositions:(void (^)(AVMutableComposition *composition, AVMutableVideoComposition *videoComposition))compositions;

+ (void)mergeVideos:(NSArray<NSURL *> *)videoURLs
       compositions:(void (^)(AVMutableComposition *composition, AVMutableVideoComposition *videoComposition))compositions;

+ (void)blurVideoWithURL:(NSURL *)url radius:(CGFloat)radius clippedSize:(CGSize)size completion:(void(^)(NSURL *outputURL, NSError *error))completion;

+ (void)blurVideoWithURL:(NSURL *)url
                  radius:(CGFloat)radius
                progress:(void(^)(CGFloat))progress
              completion:(void (^)(NSURL *, NSError *))completion;

+ (void)blurVideoWithURL:(NSURL *)url
                  radius:(CGFloat)radius
                  result:(void (^)(AVAsset *asset, AVVideoComposition *videoComposition))result;


+ (void)saveVideoToAlubmAsLivePhotoWithURL:(NSURL *)url completion:(void(^)(NSError *error))completion NS_AVAILABLE_IOS(9_1);
+ (void)saveLivePhotoToAblumWithVideoPath:(NSString *)videoPath imagePath:(NSString *)imagePath completion:(void (^)(NSError *))completion NS_AVAILABLE_IOS(9_1);
+ (void)generateLivePhotoFromVideo:(NSURL *)url
                          progress:(void(^)(CGFloat))progress
                        completion:(void(^)(PHLivePhoto *livePhoto, NSError *error))completion NS_AVAILABLE_IOS(9_1);

+ (void)generateLivePhotoFromVideo:(NSURL *)url
                  placeholderImage:(UIImage *)image
                          progress:(void(^)(CGFloat))progress
                        completion:(void(^)(PHLivePhoto *livePhoto, NSError *error))completion NS_AVAILABLE_IOS(9_1);


+ (NSURL *)generateVideoFromImage:(UIImage *)image targetSize:(CGSize)size duration:(NSTimeInterval)duration;

+ (void)mergeVideosWithoutAnimation:(NSArray *)videos
                      separateTrack:(BOOL)separateTrack
                       compositions:(void (^)(AVMutableComposition *composition, AVMutableVideoComposition *videoComposition))compositions;

+ (void)mergeVideosWronglyWithoutAnimation:(NSArray<NSURL *> *)videoURLs
                                   overlap:(BOOL)overlap
                              compositions:(void (^)(AVMutableComposition *composition, AVMutableVideoComposition *videoComposition))compositions;

+ (void)mergeVideos:(NSArray<NSURL *> *)vidoes completion:(void(^)(NSURL *url, NSError *))completion;

+ (void)addImages:(NSArray<UIImage *> *)images
  displayDuration:(NSTimeInterval)displayDuration
animationDuration:(NSTimeInterval)animationDuration
          toVideo:(NSURL *)url
   blurBackground:(BOOL)blurBackground
       completion:(void(^)(NSURL *url, NSError *error))completion;


+ (void)livePhotoWithVideo:(NSURL *)url placeholderImageURL:(NSURL *)imageURL targetSize:(CGSize)targetSize ratioTolerance:(CGFloat)ratioTolerance dynamicBlurBackground:(BOOL)dynamicBlurBackground progress:(void(^)(CGFloat progress))progress completion:(void(^)(PHLivePhoto *livePhoto, NSError *error))completion NS_AVAILABLE_IOS(9_1);

+ (void)livePhotoWithImageURLs:(NSArray *)imageURLs targetSize:(CGSize)targetSize ratioTolerance:(CGFloat)ratioTolerance
         dynamicBlurBackground:(BOOL)dynamicBlurBackground
                      progress:(void (^)(CGFloat))progress
                    completion:(void (^)(PHLivePhoto *, NSError *))completion NS_AVAILABLE_IOS(9_1);

@end
