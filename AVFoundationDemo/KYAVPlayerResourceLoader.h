//
//  KYAVPlayerResourceLoader.h
//  AVFoundationDemo
//
//  Created by leoking870 on 2018/5/8.
//  Copyright © 2018年 leoking870. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>


@interface KYAVPlayerResourceLoader : NSObject<AVAssetResourceLoaderDelegate>
+ (NSURL *)originalURLFromStreamingURL:(NSURL *)url;
+ (NSURL *)streamingAssetURL:(NSURL *)url;
@end


@interface AVPlayerItem (KYAVPlayerResourceLoader)

+ (instancetype) playerItemWithKYResourceURL:(NSURL *)resourceURL diskCacheDirectory:(NSString *)diskCacheDirectory;

@end


@interface AVAssetResourceLoadingRequest (KYAVPlayerResourceLoader)

//是否是请求文件信息的请求
- (BOOL)isContentInfoRequest;
//是否是请求文件内容的请求
- (BOOL)isContentDataRequest;

- (void)respondWithData:(NSData *)data dataOffset:(NSInteger)dataOffset;

@end

extern NSString *const KYAVPlayerResourceLoaderStreamingSchemeSuffix;
