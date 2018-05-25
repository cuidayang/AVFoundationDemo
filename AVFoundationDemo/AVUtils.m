//
//  AVUtils.m
//  KYVideoModule
//
//  Created by leoking870 on 2017/10/30.
//

#import "AVUtils.h"
#import "WQPermissionRequest.h"
@import AVFoundation;
@import Photos;

@implementation AVUtils


+ (void)mergeVideoFiles:(NSArray<NSString *> *)filepaths
              musicURL:(NSURL *)musicURL
                 atPath:(NSString *)destinationPath
          saveToLibrary:(BOOL)saveToLibrary
             completion:(void (^)(BOOL mergeSuccess, BOOL saveSuccess))completion {
    if (filepaths.count == 0) {
        if (completion) {
            completion(NO, NO);
        }
        return;
    }
    NSTimeInterval duration = 0;
    //1 创建一个compostion
    AVMutableComposition *composition = [AVMutableComposition composition];
    //2 给composition添加一个videoTrack
    AVMutableCompositionTrack *compositionTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo
                                      preferredTrackID:kCMPersistentTrackID_Invalid];
    CMTime insertPosition = kCMTimeZero;
    //3. 将视频分段添加到当前videoTrack中
    for (NSString *videoPath in filepaths) {
        AVAsset *asset = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:videoPath]
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
    
    
    if (musicURL) {
        AVMutableCompositionTrack *audioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
        AVAsset *audioAsset = [AVURLAsset URLAssetWithURL:musicURL options:@{AVURLAssetPreferPreciseDurationAndTimingKey: @(YES)}];
        CMTimeRange range = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(duration, audioAsset.duration.timescale));
        NSArray <AVAssetTrack *> *tracks = [audioAsset tracksWithMediaType:AVMediaTypeAudio];
        if (tracks.count) {
            [audioTrack insertTimeRange:range ofTrack:tracks[0] atTime:kCMTimeZero error:nil];
        }
    }

    if ([[NSFileManager defaultManager] fileExistsAtPath:destinationPath]) {
        [[NSFileManager defaultManager] removeItemAtPath:destinationPath error:nil];
    }
    AVAssetExportSession *exporterSession = [[AVAssetExportSession alloc] initWithAsset:composition presetName:AVAssetExportPresetHighestQuality];
    exporterSession.outputFileType = AVFileTypeMPEG4;
    exporterSession.outputURL = [NSURL fileURLWithPath:destinationPath]; //如果文件已存在，将造成导出失败
    exporterSession.shouldOptimizeForNetworkUse = YES; //用于互联网传输
    [exporterSession exportAsynchronouslyWithCompletionHandler:^{
        switch (exporterSession.status) {
            case AVAssetExportSessionStatusUnknown:
                if (completion) {
                    completion(NO, NO);
                }
                break;
            case AVAssetExportSessionStatusCancelled:
                NSLog(@"exporter Canceled");
                if (completion) {
                    completion(NO, NO);
                }
                break;
            case AVAssetExportSessionStatusFailed:
                NSLog(@"exporter Failed");
                if (completion) {
                    completion(NO, NO);
                }
                break;
            case AVAssetExportSessionStatusWaiting:
                NSLog(@"exporter Waiting");
                break;
            case AVAssetExportSessionStatusExporting:
                NSLog(@"exporter Exporting");
                break;
            case AVAssetExportSessionStatusCompleted:
                NSLog(@"exporter Completed");

                if (saveToLibrary) {
                    if([SINGLETONREQUEST determinePermission:WQPhotoLibrary]){
                        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                            [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:[NSURL URLWithString:destinationPath]];
                        }                                 completionHandler:^(BOOL success, NSError *_Nullable error1) {
                            if (success) {
                                if (completion) {
                                    completion(YES, YES);
                                }
                            } else if (error1) {
                                if (completion) {
                                    completion(YES, NO);
                                }
                            }
                        }];
                    }
                    else {
                        if (completion) {
                            completion(YES, NO);
                        }
                    }
//                    [SINGLETONREQUEST requestPermission:WQPhotoLibrary title:@"提示" description:@"保存铃声MV需要获取相册权限" requestResult:^(BOOL granted, NSError *error) {
//                        if (granted) {
//
//                        } else {
//                            if (completion) {
//                                completion(YES, NO);
//                            }
//                        }
//                    }];
                } else {
                    if (completion) {
                        completion(YES, NO);
                    }
                }
                break;
        }
    }];
}

@end
