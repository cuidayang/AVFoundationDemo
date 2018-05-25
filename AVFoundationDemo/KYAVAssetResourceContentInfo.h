//
//  KYAVAssetResourceContentInfo.h
//  AVFoundationDemo
//
//  Created by leoking870 on 2018/5/9.
//  Copyright © 2018年 leoking870. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KYAVAssetResourceContentInfo : NSObject
- (instancetype) init NS_UNAVAILABLE;

// make content info from http response
- (instancetype)initWithHTTPResponse:(NSHTTPURLResponse *)response NS_DESIGNATED_INITIALIZER;

// make content info from local file path
- (instancetype)initWithLocalFilePath:(NSString *)filePath NS_DESIGNATED_INITIALIZER;

@property (nonatomic, copy, readonly, nullable) NSString *contentType;
@property (nonatomic, assign, readonly) BOOL byteRangeAccessSupported;
@property (nonatomic, assign, readonly) long long contentLength;
@end
