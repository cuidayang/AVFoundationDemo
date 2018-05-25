//
//  AVFoundationUtils.m
//  AVFoundationDemo
//
//  Created by leoking870 on 2018/5/15.
//  Copyright © 2018年 leoking870. All rights reserved.
//

#import "AVFoundationUtils.h"
#import <AVFoundation/AVFoundation.h>
#import "YYCategories.h"
#import "GPUImage.h"
#import "ZYLivePhotoTool.h"
#import "CAAnimationUtils.h"
#import "UIImage+YYAdd.h"
#import "SDWebImageManager.h"
#import "UIImage+YYAdd.h"
@implementation AVFoundationUtils
+ (NSString *) defaultCacheDirectory {
    NSArray<NSString *> *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    return paths.firstObject;
}

+ (void)resizeVideoWithURL:(NSURL *)url
                targetSize:(CGSize)size
                resizeMode:(AVFoundationUtilsResizeMode)resizeMode
              compositions:(void (^)(AVMutableComposition *composition, AVMutableVideoComposition *videoComposition))compositions {
    AVAsset *videoAsset = [AVURLAsset URLAssetWithURL:url options:@{AVURLAssetPreferPreciseDurationAndTimingKey:@(YES)}];
    
    // 2 - Create AVMutableComposition object. This object will hold your AVMutableCompositionTrack instances.
    AVMutableComposition *mixComposition = [[AVMutableComposition alloc] init];
    
    // 3 - Video track
    AVMutableCompositionTrack *videoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo
                                                                        preferredTrackID:kCMPersistentTrackID_Invalid];
    AVAssetTrack *track = [[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    [videoTrack insertTimeRange:CMTimeRangeMake(CMTimeMake(0, 30), videoAsset.duration)
                        ofTrack:track
                         atTime:CMTimeMake(0, 30) error:nil];
    
    CGSize videoSize = track.naturalSize;//视频实际大小
    NSLog(@"videoSize:%@", NSStringFromCGSize(videoSize));
    // 3.1 - Create AVMutableVideoCompositionInstruction
    AVMutableVideoCompositionInstruction *mainInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    mainInstruction.timeRange = CMTimeRangeMake(CMTimeMake(0, 30), videoAsset.duration);
    
    // 3.2 - Create an AVMutableVideoCompositionLayerInstruction for the video track and fix the orientation.
    AVMutableVideoCompositionLayerInstruction *videolayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
    [videolayerInstruction setOpacity:0.0 atTime:videoAsset.duration];
    [videolayerInstruction setTransform:CGAffineTransformMakeScale(size.width/videoSize.width, size.height/videoSize.height) atTime:CMTimeMake(0, 30)];
    
    mainInstruction.layerInstructions = @[videolayerInstruction];
    
    AVMutableVideoComposition *mainCompositionInst = [AVMutableVideoComposition videoComposition];
    mainCompositionInst.renderSize = size;
    mainCompositionInst.instructions = @[mainInstruction];
    mainCompositionInst.frameDuration = CMTimeMake(1, 30);
    mainCompositionInst.renderScale = 1.0f;
    CGFloat scaleToFit = MIN(size.width/videoSize.width, size.height/videoSize.height);
    CGFloat scaleToFill = MAX(size.width/videoSize.width, size.height/videoSize.height);
    CGSize scaleToFitSize = CGSizeMake(videoSize.width * scaleToFit, videoSize.height * scaleToFit);
    CGSize scaleToFillSize = CGSizeMake(videoSize.width * scaleToFill, videoSize.height * scaleToFill);
    
    CALayer *parentLayer = [CALayer layer];
    CALayer *backgroundLayer = [CALayer layer];
    parentLayer.frame = CGRectMake(0,0,size.width,size.height);
    if (resizeMode == AVFoundationUtilsResizeModeScaleAspectFill) {
        backgroundLayer.frame = CGRectMake((size.width - scaleToFillSize.width)/2, (size.height-scaleToFillSize.height)/2, scaleToFillSize.width, scaleToFillSize.height);
    }
    else if(resizeMode == AVFoundationUtilsResizeModeScaleAspectFit){
        backgroundLayer.frame = CGRectMake((size.width - scaleToFitSize.width)/2, (size.height-scaleToFitSize.height)/2, scaleToFitSize.width, scaleToFitSize.height);
    }
    else if(resizeMode == AVFoundationUtilsResizeModeScaleToFill){
        backgroundLayer.frame = CGRectMake(0, 0, size.width, size.height);
    }
    
    [parentLayer addSublayer:backgroundLayer];
    mainCompositionInst.animationTool = [AVVideoCompositionCoreAnimationTool
                                         videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:backgroundLayer inLayer:parentLayer];
    compositions(mixComposition, mainCompositionInst);
}

+ (void)resizeVideoWithURL:(NSURL *)url
                targetSize:(CGSize)size
                resizeMode:(AVFoundationUtilsResizeMode)resizeMode
                  progress:(void(^)(CGFloat))progress
                completion:(void (^)(NSURL *, NSError *))completion {
    NSDate *methodStart = [NSDate date];
    
    [self resizeVideoWithURL:url targetSize:size resizeMode:resizeMode compositions:^(AVMutableComposition *composition, AVMutableVideoComposition *videoComposition) {
        AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:composition
                                                                          presetName:AVAssetExportPresetHighestQuality];
        NSString *path = [[self.class defaultCacheDirectory] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.mp4", [NSUUID UUID].UUIDString]];
        if ([[NSFileManager defaultManager]fileExistsAtPath:path]) {
            [[NSFileManager defaultManager]removeItemAtPath:path error:nil];
        }
        exporter.outputURL= [NSURL fileURLWithPath:path];
        exporter.outputFileType = AVFileTypeQuickTimeMovie;
        exporter.shouldOptimizeForNetworkUse = YES;
        exporter.videoComposition = videoComposition;
        [exporter exportAsynchronouslyWithCompletionHandler:^{
            NSDate *methodFinish = [NSDate date];
            NSTimeInterval executionTime = [methodFinish timeIntervalSinceDate:methodStart];
            NSLog(@"executionTime = %f", executionTime);
            if (exporter.status == AVAssetExportSessionStatusCompleted) {
                if (completion) {
                    completion([NSURL fileURLWithPath:path],  nil);
                }
            }
            else
            {
                if (completion) {
                    completion(nil,  exporter.error);
                }
            }
        }];
        [self logExporterProgress:exporter progress:progress];
    }];
}

+ (void)mergeVideosWronglyWithoutAnimation:(NSArray<NSURL *> *)videoURLs
                                   overlap:(BOOL)overlap
                       compositions:(void (^)(AVMutableComposition *composition, AVMutableVideoComposition *videoComposition))compositions {
    //1 创建一个compostion
    AVMutableComposition *composition = [AVMutableComposition composition];
    
    //2 给composition添加一个videoTrack
    AVMutableCompositionTrack *compositionTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo
                                                                           preferredTrackID:kCMPersistentTrackID_Invalid];
    CMTime insertPosition = kCMTimeZero;
    //3. 将视频分段添加到当前videoTrack中
    for (NSURL *videoURL in videoURLs) {
        AVAsset *asset = [AVURLAsset URLAssetWithURL:videoURL
                                             options:@{AVURLAssetPreferPreciseDurationAndTimingKey: @(YES)}];
        NSArray<AVAssetTrack *> *tracks = [asset tracksWithMediaType:AVMediaTypeVideo];
        if (tracks.count) {
            //4 将视频整段添加到当前videoTrack中的position处
            [compositionTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration)
                                      ofTrack:tracks[0]
                                       atTime:insertPosition
                                        error:nil];
            if (overlap) {
                insertPosition = CMTimeAdd(insertPosition, CMTimeMakeWithSeconds(CMTimeGetSeconds(asset.duration)/2, 600));
            }
            else {
                insertPosition = CMTimeAdd(insertPosition, CMTimeMakeWithSeconds(CMTimeGetSeconds(asset.duration)*3/2, 600));
            }
        }
    }
    
    compositions(composition, nil);
}




+ (void)mergeVideosWithoutAnimation:(NSArray<NSURL *> *)videoURLs
                      separateTrack:(BOOL)separateTrack
       compositions:(void (^)(AVMutableComposition *composition, AVMutableVideoComposition *videoComposition))compositions {
    //1 创建一个compostion
    AVMutableComposition *composition = [AVMutableComposition composition];
    if (separateTrack) {
        CMTime insertPosition = kCMTimeZero;
        //3. 将视频分段添加到当前videoTrack中
        for (NSURL *videoURL in videoURLs) {
            AVAsset *asset = [AVURLAsset URLAssetWithURL:videoURL
                                                 options:@{AVURLAssetPreferPreciseDurationAndTimingKey: @(YES)}];
            NSArray<AVAssetTrack *> *tracks = [asset tracksWithMediaType:AVMediaTypeVideo];
            if (tracks.count) {
                AVMutableCompositionTrack *compositionTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo
                                                                                       preferredTrackID:kCMPersistentTrackID_Invalid];
                //4 将视频整段添加到当前videoTrack中的position处
                [compositionTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration)
                                          ofTrack:tracks[0]
                                           atTime:insertPosition
                                            error:nil];
                insertPosition = CMTimeAdd(insertPosition, asset.duration);
            }
        }
    }
    else {
        //2 给composition添加一个videoTrack
        AVMutableCompositionTrack *compositionTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo
                                                                               preferredTrackID:kCMPersistentTrackID_Invalid];
        CMTime insertPosition = kCMTimeInvalid;
        //3. 将视频分段添加到当前videoTrack中
        for (NSURL *videoURL in videoURLs) {
            AVAsset *asset = [AVURLAsset URLAssetWithURL:videoURL
                                                 options:@{AVURLAssetPreferPreciseDurationAndTimingKey: @(YES)}];
            NSArray<AVAssetTrack *> *tracks = [asset tracksWithMediaType:AVMediaTypeVideo];
            if (tracks.count) {
                //4 将视频整段添加到当前videoTrack中的position处
                [compositionTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration)
                                          ofTrack:tracks[0]
                                           atTime:insertPosition
                                            error:nil];
            }
        }
    }
    
    compositions(composition, nil);
}


+ (void)overlayVideo:(NSURL *)videoURL
            position:(CGPoint)position
                size:(CGSize)size
          aboveVideo:(NSURL *)backgroundVideoURL
      backgroundSize:(CGSize)backgroundSize
        compositions:(void (^)(AVMutableComposition *composition, AVMutableVideoComposition *videoComposition))compositions {
    AVURLAsset* firstAsset = [AVURLAsset URLAssetWithURL:videoURL options:@{AVURLAssetPreferPreciseDurationAndTimingKey:@(YES)}];
    AVURLAsset * secondAsset = [AVURLAsset URLAssetWithURL:backgroundVideoURL options:@{AVURLAssetPreferPreciseDurationAndTimingKey:@(YES)}];
    
    //1 创建compostion
    AVMutableComposition* mixComposition = [[AVMutableComposition alloc] init];
    //2 给composition加入一个videoTrack, 然后将asset1的视频track添加到此videoTrack.
    AVMutableCompositionTrack *firstTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    AVAssetTrack *f_track = [[firstAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    [firstTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, firstAsset.duration)
                        ofTrack:f_track
                         atTime:kCMTimeZero
                          error:nil];
    //2 给composition加入第二个videoTrack, 然后将asset2的视频track添加到此videoTrack.
    AVMutableCompositionTrack *secondTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    AVAssetTrack *s_track = [[secondAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    [secondTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, secondAsset.duration)
                         ofTrack:s_track
                          atTime:kCMTimeZero
                           error:nil];
    
    
    AVMutableVideoCompositionInstruction * MainInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    
    MainInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, CMTIME_COMPARE_INLINE(firstAsset.duration, >, secondAsset.duration) ? firstAsset.duration : secondAsset.duration);
    //    MainInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, firstAsset.duration);
    
    //We will be creating 2 AVMutableVideoCompositionLayerInstruction objects. Each for our 2 AVMutableCompositionTrack. Here we are creating AVMutableVideoCompositionLayerInstruction for out first track. See how we make use of Affinetransform to move and scale our First Track. So it is displayed at the bottom of the screen in smaller size.(First track in the one that remains on top).
    //Note: You have to apply transformation to scale and move according to your video size.
    
    AVMutableVideoCompositionLayerInstruction *FirstlayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:firstTrack];
    //[videolayerInstruction setTransform:CGAffineTransformMakeScale(size.width/videoSize.width, size.height/videoSize.height) atTime:kCMTimeZero];
    
    //    targetSize = f_track.naturalSize;
    
    CGFloat scaleToFit = MIN(size.width/f_track.naturalSize.width, size.height/f_track.naturalSize.height);
    CGSize scaleToFitSize = CGSizeMake(f_track.naturalSize.width * scaleToFit, f_track.naturalSize.height * scaleToFit);
    CGAffineTransform Scale = CGAffineTransformMakeScale(scaleToFit,scaleToFit);
    CGAffineTransform Move = CGAffineTransformMakeTranslation(position.x,position.y);
    [FirstlayerInstruction setTransform:CGAffineTransformConcat(Scale,Move) atTime:kCMTimeZero];
    
    
    CGFloat scaleToFill = MAX(backgroundSize.width/f_track.naturalSize.width, backgroundSize.height/f_track.naturalSize.height);
    CGSize scaleToFillSize = CGSizeMake(f_track.naturalSize.width * scaleToFill, f_track.naturalSize.height * scaleToFill);
    //Here we are creating AVMutableVideoCompositionLayerInstruction for our second track.see how we make use of Affinetransform to move and scale our second Track.
    AVMutableVideoCompositionLayerInstruction *SecondlayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:secondTrack];
    scaleToFit = MIN(backgroundSize.width/s_track.naturalSize.width, backgroundSize.height/s_track.naturalSize.height);
    scaleToFill = MAX(backgroundSize.width/s_track.naturalSize.width, backgroundSize.height/s_track.naturalSize.height);
    scaleToFitSize = CGSizeMake(s_track.naturalSize.width * scaleToFit, s_track.naturalSize.height * scaleToFit);
    scaleToFillSize = CGSizeMake(s_track.naturalSize.width * scaleToFill, s_track.naturalSize.height * scaleToFill);
    CGAffineTransform SecondScale = CGAffineTransformMakeScale(scaleToFill,scaleToFill);
    CGAffineTransform SecondMove = CGAffineTransformMakeTranslation((backgroundSize.width-scaleToFillSize.width)/2,(backgroundSize.height-scaleToFillSize.height)/2);
    [SecondlayerInstruction setTransform:CGAffineTransformConcat(SecondScale,SecondMove) atTime:kCMTimeZero];
    
    //Now we add our 2 created AVMutableVideoCompositionLayerInstruction objects to our AVMutableVideoCompositionInstruction in form of an array.
    MainInstruction.layerInstructions = [NSArray arrayWithObjects:FirstlayerInstruction,SecondlayerInstruction,nil];;
    
    //Now we create AVMutableVideoComposition object.We can add multiple AVMutableVideoCompositionInstruction to this object.We have only one AVMutableVideoCompositionInstruction object in our example.You can use multiple AVMutableVideoCompositionInstruction objects to add multiple layers of effects such as fade and transition but make sure that time ranges of the AVMutableVideoCompositionInstruction objects dont overlap.
    AVMutableVideoComposition *MainCompositionInst = [AVMutableVideoComposition videoComposition];
    MainCompositionInst.instructions = [NSArray arrayWithObject:MainInstruction];
    MainCompositionInst.frameDuration = CMTimeMake(1, 30);
    MainCompositionInst.renderSize = backgroundSize;
    compositions(mixComposition, MainCompositionInst);
}


+ (void)overlayVideo:(NSURL *)videoURL onVideo:(NSURL *)backgroundVideoURL targetSize:(CGSize)targetSize compositions:(void (^)(AVMutableComposition *, AVMutableVideoComposition *))compositions {
    //First load your videos using AVURLAsset. Make sure you give the correct path of your videos.
    
    AVURLAsset* firstAsset = [AVURLAsset URLAssetWithURL:videoURL options:@{AVURLAssetPreferPreciseDurationAndTimingKey:@(YES)}];
    AVURLAsset * secondAsset = [AVURLAsset URLAssetWithURL:backgroundVideoURL options:@{AVURLAssetPreferPreciseDurationAndTimingKey:@(YES)}];

    //1 创建compostion
    AVMutableComposition* mixComposition = [[AVMutableComposition alloc] init];
    //2 给composition加入一个videoTrack, 然后将asset1的视频track添加到此videoTrack.
    AVMutableCompositionTrack *firstTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    AVAssetTrack *f_track = [[firstAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    [firstTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, firstAsset.duration)
                        ofTrack:f_track
                         atTime:kCMTimeZero
                          error:nil];
    //2 给composition加入第二个videoTrack, 然后将asset2的视频track添加到此videoTrack.
    AVMutableCompositionTrack *secondTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    AVAssetTrack *s_track = [[secondAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    [secondTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, secondAsset.duration)
                         ofTrack:s_track
                          atTime:kCMTimeZero
                           error:nil];
    
    
    AVMutableVideoCompositionInstruction * MainInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    
    MainInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, CMTIME_COMPARE_INLINE(firstAsset.duration, >, secondAsset.duration) ? firstAsset.duration : secondAsset.duration);
    //    MainInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, firstAsset.duration);
    
    //We will be creating 2 AVMutableVideoCompositionLayerInstruction objects. Each for our 2 AVMutableCompositionTrack. Here we are creating AVMutableVideoCompositionLayerInstruction for out first track. See how we make use of Affinetransform to move and scale our First Track. So it is displayed at the bottom of the screen in smaller size.(First track in the one that remains on top).
    //Note: You have to apply transformation to scale and move according to your video size.
    
    AVMutableVideoCompositionLayerInstruction *FirstlayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:firstTrack];
    //[videolayerInstruction setTransform:CGAffineTransformMakeScale(size.width/videoSize.width, size.height/videoSize.height) atTime:kCMTimeZero];
    
    //    targetSize = f_track.naturalSize;
    
    CGFloat scaleToFit = MIN(targetSize.width/f_track.naturalSize.width, targetSize.height/f_track.naturalSize.height);
    CGFloat scaleToFill = MAX(targetSize.width/f_track.naturalSize.width, targetSize.height/f_track.naturalSize.height);
    CGSize scaleToFitSize = CGSizeMake(f_track.naturalSize.width * scaleToFit, f_track.naturalSize.height * scaleToFit);
    CGSize scaleToFillSize = CGSizeMake(f_track.naturalSize.width * scaleToFill, f_track.naturalSize.height * scaleToFill);
    
    //CGFloat scale = MIN(targetSize.width/f_track.naturalSize.width,targetSize.height/f_track.naturalSize.height);
    CGAffineTransform Scale = CGAffineTransformMakeScale(scaleToFit,scaleToFit);
    
    CGAffineTransform Move = CGAffineTransformMakeTranslation((targetSize.width-scaleToFitSize.width)/2,(targetSize.height-scaleToFitSize.height)/2);
    [FirstlayerInstruction setTransform:CGAffineTransformConcat(Scale,Move) atTime:kCMTimeZero];
    
    //Here we are creating AVMutableVideoCompositionLayerInstruction for our second track.see how we make use of Affinetransform to move and scale our second Track.
    AVMutableVideoCompositionLayerInstruction *SecondlayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:secondTrack];
    scaleToFit = MIN(targetSize.width/s_track.naturalSize.width, targetSize.height/s_track.naturalSize.height);
    scaleToFill = MAX(targetSize.width/s_track.naturalSize.width, targetSize.height/s_track.naturalSize.height);
    scaleToFitSize = CGSizeMake(s_track.naturalSize.width * scaleToFit, s_track.naturalSize.height * scaleToFit);
    scaleToFillSize = CGSizeMake(s_track.naturalSize.width * scaleToFill, s_track.naturalSize.height * scaleToFill);
    CGAffineTransform SecondScale = CGAffineTransformMakeScale(scaleToFill,scaleToFill);
    CGAffineTransform SecondMove = CGAffineTransformMakeTranslation((targetSize.width-scaleToFillSize.width)/2,(targetSize.height-scaleToFillSize.height)/2);
    [SecondlayerInstruction setTransform:CGAffineTransformConcat(SecondScale,SecondMove) atTime:kCMTimeZero];
    
    //Now we add our 2 created AVMutableVideoCompositionLayerInstruction objects to our AVMutableVideoCompositionInstruction in form of an array.
    MainInstruction.layerInstructions = [NSArray arrayWithObjects:FirstlayerInstruction,SecondlayerInstruction,nil];;
    
    //Now we create AVMutableVideoComposition object.We can add multiple AVMutableVideoCompositionInstruction to this object.We have only one AVMutableVideoCompositionInstruction object in our example.You can use multiple AVMutableVideoCompositionInstruction objects to add multiple layers of effects such as fade and transition but make sure that time ranges of the AVMutableVideoCompositionInstruction objects dont overlap.
    AVMutableVideoComposition *MainCompositionInst = [AVMutableVideoComposition videoComposition];
    MainCompositionInst.instructions = [NSArray arrayWithObject:MainInstruction];
    MainCompositionInst.frameDuration = CMTimeMake(1, 30);
    MainCompositionInst.renderSize = targetSize;
    compositions(mixComposition, MainCompositionInst);
}

+ (void)overlayVideo:(NSURL *)videoURL
             onVideo:(NSURL *)backgroundVideoURL
          targetSize:(CGSize)targetSize
            progress:(void(^)(CGFloat))progress
          completion:(void(^)(NSURL *url, NSError *error))completion{
    
    [self overlayVideo:videoURL onVideo:backgroundVideoURL targetSize:targetSize compositions:^(AVMutableComposition *composition, AVMutableVideoComposition *videoComposition) {
        NSDate *methodStart = [NSDate date];
        NSString *path = [[self.class defaultCacheDirectory] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.mp4", [NSUUID UUID].UUIDString]];
        if ([[NSFileManager defaultManager]fileExistsAtPath:path]) {
            [[NSFileManager defaultManager]removeItemAtPath:path error:nil];
        }
        NSURL *url = [NSURL fileURLWithPath:path];
        
        AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:composition presetName:AVAssetExportPresetHighestQuality];
        exporter.outputURL=url;
        [exporter setVideoComposition:videoComposition];
        exporter.outputFileType = AVFileTypeQuickTimeMovie;
        
        [exporter exportAsynchronouslyWithCompletionHandler:^
         {
             NSDate *methodFinish = [NSDate date];
             NSTimeInterval executionTime = [methodFinish timeIntervalSinceDate:methodStart];
             NSLog(@"executionTime = %f", executionTime);
             if (exporter.status == AVAssetExportSessionStatusCompleted) {
                 if (completion) {
                     completion([NSURL fileURLWithPath:path],  nil);
                 }
             }
             else
             {
                 if (completion) {
                     completion(nil,  exporter.error);
                 }
             }
         }];
        [self logExporterProgress:exporter progress:progress];
    }];
}


+ (void)applyVideoEffectsToComposition:(AVMutableVideoComposition *)composition size:(CGSize)size scaleSize:(CGSize)scaleSize scaleToFillSize:(CGSize)scaleToFillSize firstFrame:(CGImageRef)firstFrame
{
    // 5
    CALayer *parentLayer = [CALayer layer];
    CALayer *videoLayer = [CALayer layer];
    CALayer *backgroundLayer = [CALayer layer];
    CALayer *frameLayer = [CALayer layer];
    parentLayer.frame = CGRectMake(0,0,size.width,size.height);
    frameLayer.frame = CGRectMake(0,0,size.width,size.height);
    backgroundLayer.frame = CGRectMake((size.width - scaleToFillSize.width)/2, (size.height-scaleToFillSize.height)/2, scaleToFillSize.width, scaleToFillSize.height);
    videoLayer.frame = CGRectMake((size.width-scaleSize.width)/2, (size.height-scaleSize.height)/2, scaleSize.width, scaleSize.height);
    
    [parentLayer addSublayer:backgroundLayer];
    [parentLayer addSublayer:frameLayer];
    frameLayer.contents = (__bridge id _Nullable)(firstFrame);
    frameLayer.opacity = .9;
    frameLayer.backgroundColor = [UIColor whiteColor].CGColor;
    [parentLayer addSublayer:videoLayer];
    composition.animationTool = [AVVideoCompositionCoreAnimationTool
                                 videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayers:@[videoLayer, backgroundLayer] inLayer:parentLayer];
}

+ (void)blurFirstFrameToComposition:(AVMutableVideoComposition *)composition size:(CGSize)size scaleSize:(CGSize)scaleSize scaleToFillSize:(CGSize)scaleToFillSize firstFrame:(CGImageRef)firstFrame
{
    // 5
    CALayer *parentLayer = [CALayer layer];
    CALayer *videoLayer = [CALayer layer];
    CALayer *backgroundLayer = [CALayer layer];
    parentLayer.frame = CGRectMake(0,0,size.width,size.height);
    backgroundLayer.frame = CGRectMake((size.width - scaleToFillSize.width)/2, (size.height-scaleToFillSize.height)/2, scaleToFillSize.width, scaleToFillSize.height);
    videoLayer.frame = CGRectMake((size.width-scaleSize.width)/2, (size.height-scaleSize.height)/2, scaleSize.width, scaleSize.height);
    
    [parentLayer addSublayer:backgroundLayer];
    backgroundLayer.contents = (__bridge id _Nullable)(firstFrame);
    
    [parentLayer addSublayer:videoLayer];
    composition.animationTool = [AVVideoCompositionCoreAnimationTool
                                 videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parentLayer];
}

+ (void)gpuBlurVideoWithURL:(NSURL *)url
                     radius:(CGFloat)radius
                   progress:(void(^)(CGFloat))progress
                 completion:(void (^)(NSURL *, NSError *))completion{
    
    AVAsset *videoAsset = [AVURLAsset URLAssetWithURL:url options:@{AVURLAssetPreferPreciseDurationAndTimingKey:@(YES)}];
    
    AVAssetTrack *track = [[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    
    CGSize targetSize = track.naturalSize;//视频实际大小
    
    
    NSString *path = [[self.class defaultCacheDirectory] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.mp4", [NSUUID UUID].UUIDString]];
    if ([[NSFileManager defaultManager]fileExistsAtPath:path]) {
        [[NSFileManager defaultManager]removeItemAtPath:path error:nil];
    }

    NSDate *methodStart = [NSDate date];
    static GPUImageMovie *movieFile= nil;
    movieFile = [[GPUImageMovie alloc]initWithURL:url];
    static GPUImageMovieWriter *movieWriter = nil;
    movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:[NSURL fileURLWithPath:path] size:targetSize fileType:AVFileTypeMPEG4 outputSettings:@{AVVideoWidthKey:@(targetSize.width), AVVideoHeightKey:@(targetSize.height), AVVideoScalingModeKey:AVVideoScalingModeResizeAspectFill,AVVideoCodecKey: AVVideoCodecH264}];
    movieWriter.shouldPassthroughAudio = YES;
    [movieFile enableSynchronizedEncodingUsingMovieWriter:movieWriter];
    [movieWriter startRecording];
    static GPUImageGaussianBlurFilter *blurFilter = nil;
    blurFilter = [[GPUImageGaussianBlurFilter alloc] init];
    blurFilter.blurRadiusInPixels = radius;
    [movieFile addTarget:blurFilter];
    [blurFilter addTarget:movieWriter];
    [movieFile startProcessing];
    __weak typeof(movieWriter) weakWriter = movieWriter;
    movieWriter.failureBlock = ^(NSError *error) {
        [blurFilter removeTarget:weakWriter];
        [weakWriter finishRecordingWithCompletionHandler:^{
            NSDate *methodFinish = [NSDate date];
            NSTimeInterval executionTime = [methodFinish timeIntervalSinceDate:methodStart];
            NSLog(@"executionTime = %f", executionTime);
            if (completion) {
                completion(nil, error);
            }
        }];
    };
    
    movieWriter.completionBlock = ^{
        [blurFilter removeTarget:weakWriter];
        [weakWriter finishRecordingWithCompletionHandler:^{
            NSDate *methodFinish = [NSDate date];
            NSTimeInterval executionTime = [methodFinish timeIntervalSinceDate:methodStart];
            NSLog(@"executionTime = %f", executionTime);
            if (completion) {
                completion([NSURL fileURLWithPath:path], nil);
            }
        }];
    };
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        while (movieFile.progress < 1) {
            if (progress) {
                progress(movieFile.progress);
            }
            [NSThread sleepForTimeInterval:0.1];
        }
    });
}

+ (void)blurVideoWithURL:(NSURL *)url
                  radius:(CGFloat)radius
              result:(void (^)(AVAsset *asset, AVVideoComposition *videoComposition))result{
    NSDate *methodStart = [NSDate date];
    //1
    AVAsset *videoAsset = [AVURLAsset URLAssetWithURL:url options:nil];
    //2
    CIFilter *gaussianBlurFilter = [CIFilter filterWithName: @"CIGaussianBlur"];
    [gaussianBlurFilter setValue:[NSNumber numberWithFloat: radius] forKey: @"inputRadius"];
    //3
    AVVideoComposition *composition = [AVVideoComposition videoCompositionWithAsset:videoAsset applyingCIFiltersWithHandler:^(AVAsynchronousCIImageFilteringRequest * _Nonnull request) {
        //滤镜
        CIImage *source = request.sourceImage;
        [gaussianBlurFilter setValue:source forKey: @"inputImage"];
        CIImage *resultImage = [gaussianBlurFilter valueForKey: @"outputImage"];
        NSLog(@"filter");
        [request finishWithImage:resultImage context:nil];
    }];
    //导出
    if (result) {
        result(videoAsset, composition);
    }
}

+ (void)blurVideoWithURL:(NSURL *)url
                  radius:(CGFloat)radius
                progress:(void(^)(CGFloat))progress
              completion:(void (^)(NSURL *, NSError *))completion{
    NSDate *methodStart = [NSDate date];
    //1
    AVAsset *videoAsset = [AVURLAsset URLAssetWithURL:url options:nil];
    //2
    CIFilter *gaussianBlurFilter = [CIFilter filterWithName: @"CIGaussianBlur"];
    [gaussianBlurFilter setValue:[NSNumber numberWithFloat: radius] forKey: @"inputRadius"];
    //3
    AVVideoComposition *composition = [AVVideoComposition videoCompositionWithAsset:videoAsset applyingCIFiltersWithHandler:^(AVAsynchronousCIImageFilteringRequest * _Nonnull request) {
        //滤镜
        CIImage *source = request.sourceImage;
        [gaussianBlurFilter setValue:source forKey: @"inputImage"];
        CIImage *resultImage = [gaussianBlurFilter valueForKey: @"outputImage"];
        [request finishWithImage:resultImage context:nil];
    }];
    //导出
    AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:videoAsset
                                                                      presetName:AVAssetExportPresetMediumQuality];
    exporter.videoComposition = composition;
    
    NSString *path = [[self.class defaultCacheDirectory] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.mp4", [NSUUID UUID].UUIDString]];
    if ([[NSFileManager defaultManager]fileExistsAtPath:path]) {
        [[NSFileManager defaultManager]removeItemAtPath:path error:nil];
    }
    exporter.outputURL= [NSURL fileURLWithPath:path];
    exporter.outputFileType = AVFileTypeMPEG4;
    exporter.shouldOptimizeForNetworkUse = YES;
    
    [exporter exportAsynchronouslyWithCompletionHandler:^{
        NSDate *methodFinish = [NSDate date];
        NSTimeInterval executionTime = [methodFinish timeIntervalSinceDate:methodStart];
        NSLog(@"executionTime = %f", executionTime);
        if (exporter.status == AVAssetExportSessionStatusCompleted) {
            if (completion) {
                completion([NSURL fileURLWithPath:path], nil);
            }
        }
        else
        {
            if (completion) {
                completion(nil, exporter.error);
            }
        }
    }];
    [self logExporterProgress:exporter progress:progress];
}

+ (void)blurVideoWithURL:(NSURL *)url radius:(CGFloat)radius clippedSize:(CGSize)size completion:(void (^)(NSURL *, NSError *))completion{
    NSDate *methodStart = [NSDate date];
    AVAsset *videoAsset = [AVURLAsset URLAssetWithURL:url options:@{AVURLAssetPreferPreciseDurationAndTimingKey:@(YES)}];
//    CIFilter *filter = [CIFilter filterWithName:@"CIGaussianBlur"];
    //[filter setValue:@(radius) forKey:kCIInputRadiusKey];
    CGSize natureSize = videoAsset.naturalSize;
    __block NSInteger value = 0;
//    __block CIImage *outputImage = nil;
    AVVideoComposition *composition = [AVVideoComposition videoCompositionWithAsset:videoAsset applyingCIFiltersWithHandler:^(AVAsynchronousCIImageFilteringRequest * _Nonnull request) {
        CIImage *source = request.sourceImage.imageByClampingToExtent;
        CIImage *image = [source imageBySettingAlphaOneInExtent:CGRectMake((natureSize.width - size.width)/2, (natureSize.height-size.height)/2, size.width, size.height)];
        CGFloat seconds = CMTimeGetSeconds(request.compositionTime);
        CIImage *blurImage = [source imageByApplyingGaussianBlurWithSigma:seconds * 10.0];
        CIImage *output = [image imageByCompositingOverImage:blurImage];
//        outputImage = output;
        [request finishWithImage:[output imageByCroppingToRect:request.sourceImage.extent] context:nil];
        value++;
        NSLog(@"value:%d",value);
    }];
    
    AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:videoAsset
                                                                      presetName:AVAssetExportPresetMediumQuality];
    NSString *path = [[self.class defaultCacheDirectory] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.mp4", [NSUUID UUID].UUIDString]];
    if ([[NSFileManager defaultManager]fileExistsAtPath:path]) {
        [[NSFileManager defaultManager]removeItemAtPath:path error:nil];
    }
    exporter.outputURL= [NSURL fileURLWithPath:path];
    exporter.outputFileType = AVFileTypeQuickTimeMovie;
    exporter.shouldOptimizeForNetworkUse = YES;
    exporter.videoComposition = composition;
    [exporter exportAsynchronouslyWithCompletionHandler:^{
        NSDate *methodFinish = [NSDate date];
        NSTimeInterval executionTime = [methodFinish timeIntervalSinceDate:methodStart];
        NSLog(@"executionTime = %f", executionTime);
        if (exporter.status == AVAssetExportSessionStatusCompleted) {
            if (completion) {
                completion([NSURL fileURLWithPath:path], nil);
            }
        }
        else
        {
            if (completion) {
                completion(nil, exporter.error);
            }
        }
    }];
}

+ (void)saveVideoToAlubmAsLivePhotoWithURL:(NSURL *)url progress:(void(^)(CGFloat))progress completion:(void (^)(NSError *))completion {
    NSDate *methodStart = [NSDate date];
    AVAsset *asset = [AVAsset assetWithURL:url];
    [[ZYLivePhotoTool shareTool]generatorOriginImgWithAsset:asset seconds:0 imageName:@"image" handleImg:^(UIImage *originImage, NSString *imagePath, NSError *error) {
        NSString *outPut = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, true).firstObject;
        NSString *newImgPath = [outPut stringByAppendingPathComponent:@"IMG.JPG"];
        NSString *newVideoPath = [outPut stringByAppendingPathComponent:@"IMG.MOV"];
        [[NSFileManager defaultManager] removeItemAtPath:newImgPath error:nil];
        [[NSFileManager defaultManager] removeItemAtPath:newVideoPath error:nil];
        [[ZYLivePhotoTool shareTool] generatorLivePhotoWithAsset:asset originImgPath:imagePath livePhotoImgPath:newImgPath livePhotoVideoPath:newVideoPath progress:progress handleLivePhoto:^(PHLivePhoto *livePhoto) {
            [[ZYLivePhotoTool shareTool] saveLivePhotoWithVideoPath:newVideoPath imagePath:newImgPath handle:^(BOOL success, NSError *error) {
                NSDate *methodFinish = [NSDate date];
                NSTimeInterval executionTime = [methodFinish timeIntervalSinceDate:methodStart];
                NSLog(@"executionTime = %f", executionTime);
                if (completion) {
                    completion(error);
                }
            }];
        }];
    }];
}

+ (void)saveLivePhotoToAblumWithVideoPath:(NSString *)videoPath imagePath:(NSString *)imagePath completion:(void (^)(NSError *))completion {
    [[ZYLivePhotoTool shareTool] saveLivePhotoWithVideoPath:videoPath imagePath:imagePath handle:^(BOOL success, NSError *error) {
        if (completion) {
            completion(error);
        }
    }];
}

+ (void)generateLivePhotoFromVideo:(NSURL *)url
                          progress:(void(^)(CGFloat))progress
                        completion:(void(^)(PHLivePhoto *livePhoto, NSError *error))completion {
    AVAsset *asset = [AVAsset assetWithURL:url];
    
    [[ZYLivePhotoTool shareTool]generatorOriginImgWithAsset:asset seconds:0 imageName:@"image" handleImg:^(UIImage *originImage, NSString *imagePath, NSError *error) {
        if (error) {
            if (completion) {
                completion(nil, error);
            }
        }
        else {
            NSString *outPut = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, true).firstObject;
            NSString *newImgPath = [outPut stringByAppendingPathComponent:[NSString stringWithFormat:@"IMG.JPG"]];
            NSString *newVideoPath = [outPut stringByAppendingPathComponent:@"IMG.MOV"];
            [[NSFileManager defaultManager] removeItemAtPath:newImgPath error:nil];
            [[NSFileManager defaultManager] removeItemAtPath:newVideoPath error:nil];
            [[ZYLivePhotoTool shareTool] generatorLivePhotoWithAsset:asset originImgPath:imagePath livePhotoImgPath:newImgPath livePhotoVideoPath:newVideoPath progress:progress  handleLivePhoto:^(PHLivePhoto *livePhoto) {
                if (completion) {
                    completion(livePhoto, nil);
                }
            }];
        }
    }];
}

+ (void)generateLivePhotoFromVideo:(NSURL *)videoURL
                  placeholderImage:(UIImage *)image
                          progress:(void(^)(CGFloat))progress
                        completion:(void(^)(PHLivePhoto *livePhoto, NSError *error))completion {
    NSData *data = UIImagePNGRepresentation(image);
    NSArray *urls = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
    NSURL *url = urls[0];
    NSString *imageURL = [url.path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.jpg",[[NSUUID UUID]UUIDString]]];
    [data writeToFile:imageURL atomically:true];
    NSString *outPut = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, true).firstObject;
    NSString *newImgPath = [outPut stringByAppendingPathComponent:[NSString stringWithFormat:@"IMG.JPG"]];
    NSString *newVideoPath = [outPut stringByAppendingPathComponent:@"IMG.MOV"];
    [[NSFileManager defaultManager] removeItemAtPath:newImgPath error:nil];
    [[NSFileManager defaultManager] removeItemAtPath:newVideoPath error:nil];
    [[ZYLivePhotoTool shareTool] generatorLivePhotoWithAsset:[AVAsset assetWithURL:videoURL] originImgPath:imageURL livePhotoImgPath:newImgPath livePhotoVideoPath:newVideoPath progress:progress handleLivePhoto:^(PHLivePhoto *livePhoto) {
        if (completion) {
            completion(livePhoto, nil);
        }
    }];
}


+ (NSURL *)generateVideoFromImage:(UIImage *)image targetSize:(CGSize)size duration:(NSTimeInterval)duration {
    
    NSString *path = [[self.class defaultCacheDirectory] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.mp4", [NSUUID UUID].UUIDString]];
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    }
    NSError *error = nil;
    AVAssetWriter *videoWriter = [[AVAssetWriter alloc] initWithURL:[NSURL fileURLWithPath:path] fileType:AVFileTypeMPEG4 error:&error];
    
    CGFloat width = ceil(size.width / 16) * 16;
    CGFloat height = ceil(size.height / 16) * 16;
    CGSize videoSize = CGSizeMake(width, height);
    NSDictionary *videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:AVVideoCodecH264, AVVideoCodecKey, @(videoSize.width), AVVideoWidthKey, @(videoSize.height), AVVideoHeightKey, nil];


    AVAssetWriterInput *videoWriterInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];
    AVAssetWriterInputPixelBufferAdaptor *adaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:videoWriterInput sourcePixelBufferAttributes:nil];

    videoWriterInput.expectsMediaDataInRealTime = YES;
    [videoWriter addInput:videoWriterInput];

    [videoWriter startWriting];
    [videoWriter startSessionAtSourceTime:kCMTimeZero];

    CVPixelBufferRef buffer = NULL;
    int frameCount = 0;
    int kRecordingFPS = 30;
//    int duration = 2;
    CMTime time = CMTimeMake(0, kRecordingFPS);
    UIImage *emptyImage = [UIImage imageWithColor:[UIColor clearColor] size:videoSize];
    
    for (UIImage *img in image?@[image, image]:@[emptyImage, emptyImage]) {
        UIImage *resizeImage = [img imageByResizeToSize:CGSizeMake(videoSize.width/img.scale, videoSize.height/img.scale) contentMode:UIViewContentModeScaleAspectFill];
        
        buffer = [self.class pixelBufferFromCGImage:resizeImage.CGImage size:videoSize];
        BOOL appendOK = NO;
        int j = 0;
        while (!appendOK && j < 30) {
            if (adaptor.assetWriterInput.readyForMoreMediaData) {
                printf("appending %d attemp %d\n", frameCount, j);
                //CMTime frameTime = CMTimeMake(frameCount, kRecordingFPS);
                appendOK = [adaptor appendPixelBuffer:buffer withPresentationTime:time];
                if (appendOK && buffer) {
                    CVBufferRelease(buffer);
                    buffer = nil;
                }
                //                time = CMTimeMake(CMTimeGetSeconds(time), 30);
                [NSThread sleepForTimeInterval:0.05];
            } else {
                printf("adaptor not ready %d, %d\n", frameCount, j);
                [NSThread sleepForTimeInterval:0.1];
            }
            j++;
        }
        time = CMTimeAdd(time, CMTimeMakeWithSeconds(duration, kRecordingFPS));
        if (!appendOK) {
            printf("error appending image %d times %d\n", frameCount, j);
        }
    }
    [videoWriter endSessionAtSourceTime:CMTimeMakeWithSeconds(duration, kRecordingFPS)];
    
    [videoWriterInput markAsFinished];
    [videoWriter finishWriting];
    return [NSURL fileURLWithPath:path];
}

+ (CVPixelBufferRef)pixelBufferFromCGImage:(CGImageRef)image size:(CGSize)size {
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey,
                             nil];
    CVPixelBufferRef pxbuffer = NULL;
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, size.width,
                                          size.height, kCVPixelFormatType_32ARGB, (__bridge CFDictionaryRef) options,
                                          &pxbuffer);
    status = status;//Added to make the stupid compiler not show a stupid warning.
    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);
    
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    NSParameterAssert(pxdata != NULL);
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pxdata, size.width,
                                                 size.height, 8, 4 * size.width, rgbColorSpace,
                                                 kCGImageAlphaNoneSkipFirst);
    NSParameterAssert(context);
    
    //CGContextTranslateCTM(context, 0, CGImageGetHeight(image));
    //CGContextScaleCTM(context, 1.0, -1.0);//Flip vertically to account for different origin
    
    CGContextDrawImage(context, CGRectMake(0, 0, CGImageGetWidth(image),
                                           CGImageGetHeight(image)), image);
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    
    return pxbuffer;
}

+ (void)exportComposition:(AVMutableComposition *)composition
         videoComposition:(AVMutableVideoComposition *)videoComposition
                 progress:(void(^)(CGFloat p))progress
               completion:(void(^)(NSURL *url, NSError *))completion {
    AVAssetExportSession *exporterSession = [[AVAssetExportSession alloc] initWithAsset:composition presetName:AVAssetExportPresetHighestQuality];
    exporterSession.outputFileType = AVFileTypeMPEG4;
    exporterSession.videoComposition = videoComposition;
    NSString *path = [[self.class defaultCacheDirectory] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.mp4", [NSUUID UUID].UUIDString]];
    if ([[NSFileManager defaultManager]fileExistsAtPath:path]) {
        [[NSFileManager defaultManager]removeItemAtPath:path error:nil];
    }
    exporterSession.outputURL= [NSURL fileURLWithPath:path];
    exporterSession.shouldOptimizeForNetworkUse = YES; //用于互联网传输
    [exporterSession exportAsynchronouslyWithCompletionHandler:^{
        if (exporterSession.status == AVAssetExportSessionStatusCompleted) {
            if (completion) {
                completion([NSURL fileURLWithPath:path],  nil);
            }
        }
        else
        {
            if (completion) {
                completion(nil,  exporterSession.error);
            }
        }
    }];
    [self logExporterProgress:exporterSession progress:progress];
}

+ (void)mergeVideos:(NSArray *)videos
       compositions:(void (^)(AVMutableComposition *composition, AVMutableVideoComposition *videoComposition))compositions {
    
    NSMutableArray<AVAsset *> *assets = [NSMutableArray arrayWithCapacity:videos.count];
    for (NSURL *url in videos) {
        [assets addObject:[AVURLAsset URLAssetWithURL:url options:@{AVURLAssetPreferPreciseDurationAndTimingKey:@(YES)}]];
    }
    CMTime transitionDuration = CMTimeMakeWithSeconds(2, 30);
    
    
    CGSize size = [assets.firstObject tracksWithMediaType:AVMediaTypeVideo].firstObject.naturalSize;
    
    AVMutableComposition *composition = [AVMutableComposition composition];
    
    
    AVMutableVideoComposition *videoComposition = [AVMutableVideoComposition videoComposition];
    videoComposition.frameDuration = CMTimeMake(1, 30); // 30 fps
    videoComposition.renderSize = size;
    
    AVMutableCompositionTrack *compositionVideoTracks[videos.count];
    for (int i = 0; i < videos.count; ++i) {
        compositionVideoTracks[i] = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    }
    CMTimeRange *passThroughTimeRanges = alloca(sizeof(CMTimeRange) * videos.count);
    CMTimeRange *transitionTimeRanges = alloca(sizeof(CMTimeRange) * videos.count);
    CMTime nextClipStartTime = kCMTimeZero;
    // 将视频插入到各自的轨道里
    for (int i = 0; i < videos.count; i++ ) {
        AVAsset *asset = [assets objectAtIndex:i];
        CMTimeRange timeRangeInAsset = CMTimeRangeMake(kCMTimeZero, [asset duration]);
        AVAssetTrack *clipVideoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
        [compositionVideoTracks[i] insertTimeRange:timeRangeInAsset
                                           ofTrack:clipVideoTrack
                                            atTime:nextClipStartTime
                                             error:nil];
        
        
        passThroughTimeRanges[i] = CMTimeRangeMake(nextClipStartTime, timeRangeInAsset.duration);
        if (i > 0) {
            passThroughTimeRanges[i].start = CMTimeAdd(passThroughTimeRanges[i].start, transitionDuration);
            passThroughTimeRanges[i].duration = CMTimeSubtract(passThroughTimeRanges[i].duration, transitionDuration);
        }
        if (i+1 < videos.count) {
            passThroughTimeRanges[i].duration = CMTimeSubtract(passThroughTimeRanges[i].duration, transitionDuration);
        }
        
        // The end of this clip will overlap the start of the next by transitionDuration.
        // (Note: this arithmetic falls apart if timeRangeInAsset.duration < 2 * transitionDuration.)
        nextClipStartTime = CMTimeAdd(nextClipStartTime, timeRangeInAsset.duration);
        nextClipStartTime = CMTimeSubtract(nextClipStartTime, transitionDuration);
        
        // Remember the time range for the transition to the next item.
        if (i+1 < videos.count) {
            transitionTimeRanges[i] = CMTimeRangeMake(nextClipStartTime, transitionDuration);
        }
    }
    
    // Set up the video composition to perform cross dissolve or diagonal wipe transitions between clips.
    NSMutableArray *instructions = [NSMutableArray array];

    // Cycle between "pass through A", "transition from A to B", "pass through B"
    for (int i = 0; i < videos.count; i++ ) {
        // Pass through clip i.
        AVMutableVideoCompositionInstruction *passThroughInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
        passThroughInstruction.timeRange = passThroughTimeRanges[i];
        AVMutableVideoCompositionLayerInstruction *passThroughLayer = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:compositionVideoTracks[i]];

        passThroughInstruction.layerInstructions = [NSArray arrayWithObject:passThroughLayer];
        [instructions addObject:passThroughInstruction];

        if (i+1 < videos.count) {
            // Add transition from clip i to clip i+1.

            AVMutableVideoCompositionInstruction *transitionInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
            transitionInstruction.timeRange = transitionTimeRanges[i];
            AVMutableVideoCompositionLayerInstruction *fromLayer = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:compositionVideoTracks[i]];
            AVMutableVideoCompositionLayerInstruction *toLayer = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:compositionVideoTracks[i+1]];
            
            if (i % 5 == 0) {
                //渐变
                [fromLayer setOpacityRampFromStartOpacity:1.0 toEndOpacity:0.0 timeRange:transitionTimeRanges[i]];
                [toLayer setOpacityRampFromStartOpacity:0.0 toEndOpacity:1.0 timeRange:transitionTimeRanges[i]];
            }
            else if(i % 5 == 1){
                [fromLayer setCropRectangleRampFromStartCropRectangle:CGRectMake(0, 0, size.width, size.height) toEndCropRectangle:CGRectMake(0, 0, size.width, 0) timeRange:transitionTimeRanges[i]];
                
                [toLayer setCropRectangleRampFromStartCropRectangle:CGRectMake(0, size.height, size.width, 0) toEndCropRectangle:CGRectMake(0, 0, size.width, size.height) timeRange:transitionTimeRanges[i]];
            }
            else if(i % 5 == 2){
                [fromLayer setCropRectangleRampFromStartCropRectangle:CGRectMake(0, 0, size.width, size.height) toEndCropRectangle:CGRectMake(0, size.height, size.width, size.height) timeRange:transitionTimeRanges[i]];
                [toLayer setCropRectangleRampFromStartCropRectangle:CGRectMake(0, 0, size.width, 0) toEndCropRectangle:CGRectMake(0, 0, size.width, size.height) timeRange:transitionTimeRanges[i]];
            }
            else if(i % 5 == 3){
                [fromLayer setTransformRampFromStartTransform:CGAffineTransformMakeRotation(0) toEndTransform:CGAffineTransformMakeRotation(M_PI_2) timeRange:transitionTimeRanges[i]];
                [toLayer setTransformRampFromStartTransform:CGAffineTransformMakeRotation(0) toEndTransform:CGAffineTransformMakeRotation(0) timeRange:transitionTimeRanges[i]];
                }
            else if(i % 5 == 4){
                [fromLayer setTransformRampFromStartTransform:CGAffineTransformMakeScale(1, 1) toEndTransform:CGAffineTransformMakeScale(0, 0) timeRange:transitionTimeRanges[i]];
                [toLayer setTransformRampFromStartTransform:CGAffineTransformMakeScale(1, 1) toEndTransform:CGAffineTransformMakeScale(1, 1) timeRange:transitionTimeRanges[i]];
            }
            transitionInstruction.layerInstructions = [NSArray arrayWithObjects:fromLayer, toLayer, nil];
            [instructions addObject:transitionInstruction];
        }
    }
    
    videoComposition.instructions = instructions;
 
    compositions(composition, videoComposition);
}

+ (void)mergeVideos:(NSArray<NSURL *> *)vidoes completion:(void (^)(NSURL *, NSError *))completion {
    NSTimeInterval duration = 0;
    //1 创建一个compostion
    AVMutableComposition *composition = [AVMutableComposition composition];
    //2 给composition添加一个videoTrack
    AVMutableCompositionTrack *compositionTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo
                                                                           preferredTrackID:kCMPersistentTrackID_Invalid];
    CMTime insertPosition = kCMTimeZero;
    //3. 将视频分段添加到当前videoTrack中
    for (NSURL *url in vidoes) {
        AVAsset *asset = [AVURLAsset URLAssetWithURL:url
                                             options:@{AVURLAssetPreferPreciseDurationAndTimingKey: @(YES)}];
        NSArray<AVAssetTrack *> *tracks = [asset tracksWithMediaType:AVMediaTypeVideo];
        if (tracks.count) {
            //4 将视频整段添加到当前videoTrack中的position处
            [compositionTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration)
                                      ofTrack:tracks[0]
                                       atTime:insertPosition
                                        error:nil];
            
            insertPosition = CMTimeAdd(insertPosition, asset.duration);
            duration += CMTimeGetSeconds(asset.duration);
        }
    }
    
    AVAssetExportSession *exporterSession = [[AVAssetExportSession alloc] initWithAsset:composition presetName:AVAssetExportPresetHighestQuality];
    exporterSession.outputFileType = AVFileTypeMPEG4;
    NSString *path = [[self.class defaultCacheDirectory] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.mp4", [NSUUID UUID].UUIDString]];
    if ([[NSFileManager defaultManager]fileExistsAtPath:path]) {
        [[NSFileManager defaultManager]removeItemAtPath:path error:nil];
    }
    exporterSession.outputURL= [NSURL fileURLWithPath:path];
    exporterSession.shouldOptimizeForNetworkUse = YES; //用于互联网传输
    [exporterSession exportAsynchronouslyWithCompletionHandler:^{
        if (exporterSession.status == AVAssetExportSessionStatusCompleted) {
            if (completion) {
                completion([NSURL fileURLWithPath:path],  nil);
            }
        }
        else
        {
            if (completion) {
                completion(nil,  exporterSession.error);
            }
        }
    }];
}

+ (CGRect)frameWithImage:(UIImage* )image videoSize:(CGSize)videoSize {
    CGSize imageSize = CGSizeMake(image.size.width * image.scale, image.size.height * image.scale);
    CGFloat scaleToFit = MIN(videoSize.width/imageSize.width, videoSize.height/imageSize.height);
    CGSize scaleToFitSize = CGSizeMake(imageSize.width * scaleToFit, imageSize.height * scaleToFit);
    return CGRectMake((videoSize.width-scaleToFitSize.width)/2, (videoSize.height-scaleToFitSize.height)/2, scaleToFitSize.width, scaleToFitSize.height);
}

+ (void)addImages:(NSArray<UIImage *> *)images
  displayDuration:(NSTimeInterval)displayDuration
animationDuration:(NSTimeInterval)animationDuration
          toVideo:(NSURL *)url
   blurBackground:(BOOL)blurBackground
       completion:(void(^)(NSURL *url, NSError *error))completion progress:(void(^)(CGFloat progress))progress{
    NSDate *methodStart = [NSDate date];
    AVAsset *videoAsset = [AVURLAsset URLAssetWithURL:url options:@{AVURLAssetPreferPreciseDurationAndTimingKey:@(YES)}];
    
    // 2 - Create AVMutableComposition object. This object will hold your AVMutableCompositionTrack instances.
    AVMutableComposition *mixComposition = [[AVMutableComposition alloc] init];
    
    // 3 - Video track
    AVMutableCompositionTrack *videoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo
                                                                        preferredTrackID:kCMPersistentTrackID_Invalid];
    CGFloat duration = CMTimeGetSeconds(videoAsset.duration);
    AVAssetTrack *track = [[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    
    [videoTrack insertTimeRange:CMTimeRangeMake(CMTimeMake(0, 30), videoAsset.duration)
                        ofTrack:track
                         atTime:CMTimeMake(0, 30) error:nil];
    
    CGSize videoSize = track.naturalSize;//视频实际大小
    
    // 3.1 - Create AVMutableVideoCompositionInstruction
    AVMutableVideoCompositionInstruction *mainInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    mainInstruction.timeRange = CMTimeRangeMake(CMTimeMake(0, 30), videoAsset.duration);
    
    // 3.2 - Create an AVMutableVideoCompositionLayerInstruction for the video track and fix the orientation.
    
    AVMutableVideoComposition *mainCompositionInst = [AVMutableVideoComposition videoComposition];
    mainCompositionInst.renderSize = videoTrack.naturalSize;
    //mainCompositionInst.renderScale = MIN(size.width/videoSize.width, size.height/videoSize.height);
    mainCompositionInst.instructions = @[mainInstruction];
    mainCompositionInst.frameDuration = CMTimeMake(1, 30);
    mainCompositionInst.renderScale = 1.0f;
    
    
    CALayer *parentLayer = [CALayer layer];
    CALayer *videoLayer = [CALayer layer];
    CALayer *backgroundLayer = [CALayer layer];
    CALayer *imageLayers = [CALayer layer];
    
    
    
    parentLayer.frame = CGRectMake(0,0,videoSize.width,videoSize.height);
    videoLayer.frame = CGRectMake(0,0,videoSize.width,videoSize.height);
    imageLayers.frame = CGRectMake(0,0,videoSize.width,videoSize.height);
    backgroundLayer.frame = CGRectMake(0, 0, videoSize.width, videoSize.height);
    backgroundLayer.backgroundColor = [UIColor clearColor].CGColor;
    backgroundLayer.contentsGravity = @"resizeAspectFill";
    [parentLayer addSublayer:videoLayer];
    [parentLayer addSublayer:backgroundLayer];
    [parentLayer addSublayer:imageLayers];
    
    
    
    imageLayers.backgroundColor = [UIColor clearColor].CGColor;
    
    
    CALayer *firstLayer = [CALayer layer];
    firstLayer.contents = (__bridge id _Nullable)(images.firstObject.CGImage);

    firstLayer.frame = [self frameWithImage:images.firstObject videoSize:videoSize];
    [imageLayers addSublayer:firstLayer];
    
    CALayer *lastLayer = firstLayer;
    CALayer *currentLayer = nil;
    CGFloat beginTime = AVCoreAnimationBeginTimeAtZero;
    
    NSMutableArray *contents = [NSMutableArray arrayWithCapacity:images.count];
    
    for (int i = 1; i < images.count; ++i) {
        UIImage *img = images[i];
        CALayer *layer = [CALayer layer];
        layer.contents = (__bridge id _Nullable)(img.CGImage);
        if (blurBackground) {
            UIImage *blurImage = [self blurImageWithImage:img];
            if (blurImage.CGImage) {
                [contents addObject:(__bridge id _Nullable)(blurImage.CGImage)];
            }
            else {
                [contents addObject:(__bridge id _Nullable)(img.CGImage)];
            }
        }
        
        layer.frame = [self frameWithImage:images[i] videoSize:videoSize];
        layer.opacity = 0;
        currentLayer = layer;
        [imageLayers insertSublayer:currentLayer below:lastLayer];
        //做动画
        [self addRandomAnimationToFromLayer:lastLayer
                                    toLayer:currentLayer
                                  beginTime:beginTime + displayDuration
                                   duration:animationDuration
                                       size:videoSize];
        lastLayer = currentLayer;
        beginTime = beginTime + (displayDuration+animationDuration);
    }
    if (contents.count) {
        CAAnimation *animation = [CAAnimationUtils animateContentWithImages:contents];
        animation.beginTime = AVCoreAnimationBeginTimeAtZero;
        animation.duration = (displayDuration+animationDuration)*images.count;
        [backgroundLayer addAnimation:animation forKey:nil];
    }
    
    
    CALayer *backLayer = [CALayer layer];
    backLayer.contents = (__bridge id _Nullable)(images.firstObject.CGImage);
    backLayer.frame = [self frameWithImage:images.firstObject videoSize:videoSize];;
    backLayer.opacity = 0;
    currentLayer = backLayer;
    [imageLayers insertSublayer:currentLayer below:lastLayer];
    [self addRandomAnimationToFromLayer:lastLayer
                                toLayer:currentLayer
                              beginTime:beginTime + displayDuration
                               duration:animationDuration
                                   size:videoSize];
    
    
    mainCompositionInst.animationTool = [AVVideoCompositionCoreAnimationTool  videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parentLayer];
    
    
    AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:mixComposition
                                                                      presetName:AVAssetExportPresetHighestQuality];
    NSString *path = [[self.class defaultCacheDirectory] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.mp4", [NSUUID UUID].UUIDString]];
    if ([[NSFileManager defaultManager]fileExistsAtPath:path]) {
        [[NSFileManager defaultManager]removeItemAtPath:path error:nil];
    }
    exporter.outputURL= [NSURL fileURLWithPath:path];
    exporter.outputFileType = AVFileTypeQuickTimeMovie;
    exporter.shouldOptimizeForNetworkUse = YES;
    exporter.videoComposition = mainCompositionInst;
    [exporter exportAsynchronouslyWithCompletionHandler:^{
        
        NSDate *methodFinish = [NSDate date];
        NSTimeInterval executionTime = [methodFinish timeIntervalSinceDate:methodStart];
        NSLog(@"executionTime = %f", executionTime);
        if (exporter.status == AVAssetExportSessionStatusCompleted) {
            if (completion) {
                completion([NSURL fileURLWithPath:path],  nil);
            }
        }
        else
        {
            if (completion) {
                completion(nil,  exporter.error);
            }
        }
    }];
    [self logExporterProgress:exporter progress:progress];
}



+ (void)addRandomAnimationToFromLayer:(CALayer *)fromLayer toLayer:(CALayer *)toLayer beginTime:(CFTimeInterval)beginTime duration:(NSTimeInterval)duration size:(CGSize)size{
    fromLayer.anchorPoint = CGPointMake(0.5, 0.5);
    toLayer.anchorPoint = CGPointMake(0.5, 0.5);
    //做位移动画
    //上下左右:4种
    CGPoint center = CGPointMake(size.width/2, size.height/2);
    CAAnimation *visible = [CAAnimationUtils opacityFrom:0 to:1];
    visible.beginTime = beginTime;
    visible.duration = 1;
    
    CAAnimation *disppear = [CAAnimationUtils opacityFrom:1 to:0];
    disppear.beginTime = beginTime+duration;
    disppear.duration = 1;
    
    CAAnimation *outAnimation = nil;
    CAAnimation *inAnimation = nil;
    
    int i = arc4random_uniform(15);
    
    if (i == 0) {//向左
        outAnimation = [CAAnimationUtils moveFrom:center to:CGPointMake(size.width/2+size.width, size.height/2)];
        inAnimation = [CAAnimationUtils moveFrom:CGPointMake(-size.width/2, size.height/2) to:center];
    }
    else if(i == 1)//向左
    {
        outAnimation = [CAAnimationUtils moveFrom:center to:CGPointMake(-size.width/2, size.height/2)];
        inAnimation = [CAAnimationUtils moveFrom:CGPointMake(size.width/2+size.width, size.height/2) to:center];
    }
    else if(i == 2){//向下
        outAnimation = [CAAnimationUtils moveFrom:center to:CGPointMake(size.width/2, size.height/2+size.height)];
        inAnimation = [CAAnimationUtils moveFrom:CGPointMake(size.width/2, -size.height/2) to:center];
    }
    else if(i == 3){
        outAnimation = [CAAnimationUtils moveFrom:center to:CGPointMake(size.width/2, -size.height/2)];
        inAnimation = [CAAnimationUtils moveFrom:CGPointMake(size.width/2, size.height/2+size.height) to:center];
    }
    else if (i == 4){
        outAnimation = [CAAnimationUtils cubeRotateAlongAxis:CAAnimationRotateAxisY fromAngle:0 toAngle:M_PI_2 value:size.width/2];
        inAnimation = [CAAnimationUtils cubeRotateAlongAxis:CAAnimationRotateAxisY fromAngle:-M_PI_2 toAngle:0 value:size.width/2];
    }
    else if(i == 5){
        outAnimation = [CAAnimationUtils cubeRotateAlongAxis:CAAnimationRotateAxisY fromAngle:0 toAngle:-M_PI_2 value:size.width/2];
        inAnimation = [CAAnimationUtils cubeRotateAlongAxis:CAAnimationRotateAxisY fromAngle:M_PI_2 toAngle:0 value:size.width/2];
    }
    else if(i == 6){
        outAnimation = [CAAnimationUtils cubeRotateAlongAxis:CAAnimationRotateAxisX fromAngle:0 toAngle:M_PI_2 value:size.height/2];
        inAnimation = [CAAnimationUtils cubeRotateAlongAxis:CAAnimationRotateAxisX fromAngle:-M_PI_2 toAngle:0 value:size.height/2];
    }
    else if(i == 7){
        outAnimation = [CAAnimationUtils cubeRotateAlongAxis:CAAnimationRotateAxisX fromAngle:0 toAngle:-M_PI_2 value:size.height/2];
        inAnimation = [CAAnimationUtils cubeRotateAlongAxis:CAAnimationRotateAxisX fromAngle:M_PI_2 toAngle:0 value:size.height/2];
    }
    else if(i == 8)
    {
        //水平翻转
        outAnimation = [CAAnimationUtils flipAlongAxis:CAAnimationRotateAxisX fromAngle:0 toAngle:M_PI_2 value:size.width/2];
        inAnimation = [CAAnimationUtils flipAlongAxis:CAAnimationRotateAxisX fromAngle:-M_PI_2 toAngle:0 value:size.width/2];
        outAnimation.beginTime = beginTime;
        outAnimation.duration = duration/2;
        inAnimation.beginTime = beginTime + duration/2;
        inAnimation.duration = duration/2;
        
        visible.beginTime = beginTime + duration/2;
        visible.duration = 1;
    }
    else if(i == 9){
        //垂直翻转
        outAnimation = [CAAnimationUtils flipAlongAxis:CAAnimationRotateAxisY fromAngle:0 toAngle:-M_PI_2 value:size.height/2];
        inAnimation = [CAAnimationUtils flipAlongAxis:CAAnimationRotateAxisY fromAngle:M_PI_2 toAngle:0 value:size.height/2];
        outAnimation.beginTime = beginTime;
        outAnimation.duration = duration/2;
        inAnimation.beginTime = beginTime + duration/2;
        inAnimation.duration = duration/2;
        visible.beginTime = beginTime + duration/2;
        visible.duration = 1;
    }
    else if(i == 10){
        outAnimation = [CAAnimationUtils scaleFrom:1 to:0];
        CAAnimation *moveOut = [CAAnimationUtils moveWithPositions:@[[NSValue valueWithCGPoint:center], [NSValue valueWithCGPoint:CGPointMake(size.width/2, size.height/4)] ,[NSValue valueWithCGPoint:center]]];
        moveOut.beginTime = beginTime;
        moveOut.duration = duration;
        [fromLayer addAnimation:moveOut forKey:nil];
        inAnimation = [CAAnimationUtils scaleFrom:0 to:1];
        CAAnimation *moveIn = [CAAnimationUtils moveWithPositions:@[[NSValue valueWithCGPoint:center], [NSValue valueWithCGPoint:CGPointMake(size.width/2, size.height*3/4)] ,[NSValue valueWithCGPoint:center]]];
        moveIn.beginTime = beginTime;
        moveIn.duration = duration;
        [toLayer addAnimation:moveIn forKey:nil];
    }
    else if(i == 11){
        outAnimation = [CAAnimationUtils rotateFrom:0 to:M_PI * 2];
        CAAnimation *moveOut = [CAAnimationUtils moveto:CGPointMake(-size.width/2, size.height)];
        moveOut.beginTime = beginTime;
        moveOut.duration = duration;
        [fromLayer addAnimation:moveOut forKey:nil];
        
    }
    else if(i == 12){
        outAnimation = [CAAnimationUtils rotateFrom:0 to:-M_PI * 2];
        CAAnimation *moveOut = [CAAnimationUtils moveto:CGPointMake(size.width/2+size.width, size.height)];
        moveOut.beginTime = beginTime;
        moveOut.duration = duration;
        [fromLayer addAnimation:moveOut forKey:nil];
    }
    else if(i == 13){
        CAShapeLayer *circleLayer = [CAShapeLayer layer];
        circleLayer.fillColor = [UIColor clearColor].CGColor;//这个必须透明，因为这样内圆才是不透明的
        circleLayer.strokeColor = [UIColor yellowColor].CGColor;//注意这个必须不能透明，因为实际上是这个显示出后面的图片了
        
        CGFloat diameter = 40;
        UIBezierPath *path = [UIBezierPath bezierPathWithOvalInRect:CGRectMake((size.width - diameter) / 2, (size.height - diameter) / 2, diameter, diameter)];
        
        diameter = sqrt(size.width * size.width + size.height * size.height);
        UIBezierPath *toPath = [UIBezierPath bezierPathWithOvalInRect:CGRectMake((size.width - diameter) / 2, (size.height - diameter) / 2, diameter, diameter)];;
        
        circleLayer.path = toPath.CGPath;
        circleLayer.lineWidth = diameter;
        fromLayer.mask = circleLayer;
        
        //让圆的变大的动画
        CABasicAnimation *pathAnimation = [CABasicAnimation animationWithKeyPath:@"path"];
        pathAnimation.toValue = (id)path.CGPath;
        //让圆的线的宽度变大的动画，效果是内圆变小
        CABasicAnimation *lineWidthAnimation = [CABasicAnimation animationWithKeyPath:NSStringFromSelector(@selector(lineWidth))];
        lineWidthAnimation.toValue = @(1);
        lineWidthAnimation.removedOnCompletion = NO;
        lineWidthAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        lineWidthAnimation.fillMode = kCAFillModeForwards;
        lineWidthAnimation.beginTime = beginTime;
        lineWidthAnimation.duration = duration;
        pathAnimation.removedOnCompletion = NO;
        pathAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        pathAnimation.fillMode = kCAFillModeForwards;
        pathAnimation.beginTime = beginTime;
        pathAnimation.duration = duration;
        [circleLayer addAnimation:lineWidthAnimation forKey:nil];
        [circleLayer addAnimation:pathAnimation forKey:nil];
    }
    else if(i == 14){
        CAGradientLayer *gradientLayer = [CAGradientLayer layer];
        gradientLayer.colors = @[(id)[UIColor clearColor].CGColor, (id)UIColor.blackColor.CGColor];
        gradientLayer.frame = fromLayer.bounds;
        gradientLayer.locations = @[@0, @0, @0];
        gradientLayer.startPoint = CGPointMake(0,0);
        gradientLayer.endPoint = CGPointMake(1,1);
        fromLayer.mask = gradientLayer;
        
        CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"locations"];
        animation.fromValue = @[@0.0, @0.0, @0.25];
        animation.toValue = @[@0.75, @1.0, @1.0];
        animation.removedOnCompletion = NO;
        animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        animation.fillMode = kCAFillModeForwards;
        animation.beginTime = beginTime;
        animation.duration = duration;
        [gradientLayer addAnimation:animation forKey:nil];
        
    }
    
    if (outAnimation.beginTime == 0) {
        outAnimation.beginTime = beginTime;
        outAnimation.duration = duration;
    }
    
    [fromLayer addAnimation:outAnimation forKey:nil];
    [fromLayer addAnimation:disppear forKey:nil];
    
    if (inAnimation.beginTime == 0) {
        inAnimation.beginTime = beginTime;
        inAnimation.duration = duration;
    }
    [toLayer addAnimation:inAnimation forKey:nil];
    [toLayer addAnimation:visible forKey:nil];
}

+ (void)logExporterProgress:(AVAssetExportSession *)exporter progress:(void(^)(CGFloat progress))progress{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        while (exporter.progress < 1) {
            if (progress) {
                progress(exporter.progress);
            }
            [NSThread sleepForTimeInterval:0.1];
        }
    });
}

+ (UIImage *)blurImageWithImage:(UIImage *)image {
    GPUImageGaussianBlurFilter *filter = [[GPUImageGaussianBlurFilter alloc] init];
    filter.blurRadiusInPixels = 10;
    GPUImagePicture *pic = [[GPUImagePicture alloc] initWithImage:image];
    [pic addTarget:filter];
    [pic processImage];
    [filter useNextFrameForImageCapture];
    UIImage *processedImage = [filter imageFromCurrentFramebufferWithOrientation:image.imageOrientation];
    return processedImage;
}

+ (void)livePhotoWithImageURLs:(NSArray *)imageURLs
                    targetSize:(CGSize)targetSize
                ratioTolerance:(CGFloat)ratioTolerance
         dynamicBlurBackground:(BOOL)dynamicBlurBackground
                      progress:(void (^)(CGFloat))progress
                    completion:(void (^)(PHLivePhoto *, NSError *))completion {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSMutableArray *images = [NSMutableArray arrayWithCapacity:imageURLs.count];
        for (NSString *imageUrl in imageURLs) {
            UIImage *image = [[[SDWebImageManager sharedManager]imageCache]imageFromCacheForKey:[[SDWebImageManager sharedManager]cacheKeyForURL:[NSURL URLWithString:imageUrl]]];
            [images addObject:image];
        }
        
        NSURL *video = [self generateVideoFromImage:nil targetSize:targetSize duration:3.5 * imageURLs.count];
        [self addImages:images displayDuration:2 animationDuration:1.5 toVideo:video blurBackground:YES completion:^(NSURL *outputurl, NSError *error) {
            if (error) {
                [[NSFileManager defaultManager]removeItemAtURL:outputurl error:nil];
                if (completion) {
                    completion(nil, error);
                }
            }
            else {
                NSLog(@"成品视频地址:%@", outputurl);
                [self generateLivePhotoFromVideo:outputurl progress:^(CGFloat p){
                    NSLog(@"p:%f",p);
                    progress?progress(0.5 + p /2 ):nil;
                } completion:^(PHLivePhoto *livePhoto, NSError *error) {
                    [[NSFileManager defaultManager]removeItemAtURL:outputurl error:nil];
                    if (error) {
                        if (completion) {
                            completion(nil, error);
                        }
                    }
                    else {
                        if (completion) {
                            completion(livePhoto, nil);
                        }
                    }
                }];
            }
        } progress:^(CGFloat p) {
            progress?progress(p/2):nil;
        }];
    });
}

+ (void)livePhotoWithVideo:(NSURL *)url
       placeholderImageURL:(NSURL *)imageURL
                targetSize:(CGSize)targetSize
            ratioTolerance:(CGFloat)ratioTolerance
     dynamicBlurBackground:(BOOL)dynamicBlurBackground
                  progress:(void (^)(CGFloat))progress
                completion:(void (^)(PHLivePhoto *, NSError *))completion {
    
    CGFloat ratio = targetSize.width / targetSize.height;
    CGSize blurVideoSize = CGSizeMake(targetSize.width/10, targetSize.height/10);
    AVURLAsset * asset = [AVURLAsset URLAssetWithURL:url options:nil];
    CGSize natureSize = [[[asset tracksWithMediaType:AVMediaTypeVideo]firstObject]naturalSize];
    CGFloat realRatio = natureSize.width / natureSize.height;
    
    void (^block)(NSURL *) = ^(NSURL *outputURL){
        if (imageURL) {
            UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:imageURL]];
            [self generateLivePhotoFromVideo:outputURL placeholderImage:[image imageByResizeToSize:targetSize contentMode:UIViewContentModeScaleAspectFill] progress:^(CGFloat p){
                progress?progress(p / 4.0f + 0.75f):nil;
            } completion:^(PHLivePhoto *livePhoto, NSError *error) {
                if (error) {
                    if (completion) {
                        completion(nil, error);
                    }
                }
                else {
                    if (completion) {
                        completion(livePhoto, nil);
                    }
                }
                [[NSFileManager defaultManager]removeItemAtURL:outputURL error:nil];
            }];
        }
        else {
            [self generateLivePhotoFromVideo:outputURL  progress:^(CGFloat p){
                progress?progress(p / 4.0f + 0.75f):nil;
            } completion:^(PHLivePhoto *livePhoto, NSError *error) {
                if (error) {
                    if (completion) {
                        completion(nil, error);
                    }
                }
                else {
                    if (completion) {
                        completion(livePhoto, nil);
                    }
                }
                [[NSFileManager defaultManager]removeItemAtURL:outputURL error:nil];
            }];
        }
    };
    if (realRatio > (ratio - ratioTolerance) && realRatio < (ratio + ratioTolerance)) {
        //不需要模糊背景, 直接修改大小到targetSize, 然后转livePhoto
        [self resizeVideoWithURL:url
                      targetSize:targetSize
                      resizeMode:AVFoundationUtilsResizeModeScaleAspectFill
                        progress:^(CGFloat p){
                            progress?progress(p * 0.75f):nil;
                        }
                      completion:^(NSURL *outputURL, NSError *e) {
            if (outputURL) {
                block(outputURL);
            }
            else {
                if (completion) {
                    completion(nil, e);
                }
            }
        }];
    }
    else {
        //比例相差太大, 需要先模糊背景, 然后叠加视频, 再转livePhoto
        [self resizeVideoWithURL:url
                      targetSize:blurVideoSize
                      resizeMode:AVFoundationUtilsResizeModeScaleAspectFill
                        progress:^(CGFloat p){
                            progress?progress(p / 4.0f):nil;
                        }
                      completion:^(NSURL *resizeUrl, NSError *error) {
            if (error) { if (completion) { completion(nil, error);return; } }
                          [self gpuBlurVideoWithURL:resizeUrl radius:10  progress:^(CGFloat p){
                            progress?progress(p / 4.0f + 0.25f):nil;
                          } completion:^(NSURL *blurUrl, NSError *error) {
                if (error) { if (completion) { completion(nil, error);return; } }
                              [self overlayVideo:url onVideo:blurUrl targetSize:targetSize progress:^(CGFloat p){
                                  progress?progress(p / 4.0f + 0.5f):nil;
                              } completion:^(NSURL *outputurl, NSError *error) {
                    if (error) { if (completion) { completion(nil, error);return; } }
                                  block(outputurl);
                                  [[NSFileManager defaultManager]removeItemAtURL:resizeUrl error:nil];
                                  [[NSFileManager defaultManager]removeItemAtURL:blurUrl error:nil];
                }];
            }];
        }];
    }
}




@end
