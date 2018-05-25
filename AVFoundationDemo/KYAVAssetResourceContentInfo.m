//
//  KYAVAssetResourceContentInfo.m
//  AVFoundationDemo
//
//  Created by leoking870 on 2018/5/9.
//  Copyright © 2018年 leoking870. All rights reserved.
//

#import "KYAVAssetResourceContentInfo.h"
#import <MobileCoreServices/MobileCoreServices.h>
@implementation KYAVAssetResourceContentInfo
- (instancetype)initWithHTTPResponse:(NSHTTPURLResponse *)response {
    self = [super init];
    if (self) {
        NSString *mimeType = [response MIMEType];
        CFStringRef contentType = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, (__bridge CFStringRef)(mimeType), NULL);
        _contentType = CFBridgingRelease(contentType);
        NSDictionary *headers = response.allHeaderFields;
        NSString *contentRange = [headers objectForKey:@"Content-Range"];
        _byteRangeAccessSupported = contentRange.length > 0;
        long long contentLength = 0;
        NSArray<NSString *> *ranges = [contentRange componentsSeparatedByString:@"/"];
        if (ranges.count > 1) {
            NSString *contentLengthString = [ranges.lastObject stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            contentLength = [contentLengthString longLongValue];
        }
        _contentLength = contentLength ?: response.expectedContentLength;
    }
    return self;
}

- (instancetype)initWithLocalFilePath:(NSString *)filePath {
    self = [super init];
    if (self) {
        NSFileManager *manager = [NSFileManager defaultManager];
        BOOL isDir = NO;
        BOOL fileExist = [manager fileExistsAtPath:filePath isDirectory:&isDir];
        if (fileExist && !isDir) {
            NSString *extension = filePath.pathExtension;
            NSString *mimeType = nil;
            if ([extension isEqualToString:@"mp4"]) {
                mimeType = [NSString stringWithFormat:@"video/%@",extension];
            }
            else {
                mimeType = @"application/octet-stream";
            }
            
            CFStringRef contentType = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, (__bridge CFStringRef)(mimeType), NULL);
            _contentType = CFBridgingRelease(contentType);    
            _byteRangeAccessSupported = YES;
            _contentLength = [[manager attributesOfItemAtPath:filePath error:nil] fileSize];
        }
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@-%p> contentType : %@ contentLength : %lld rangeSupport : %zd",NSStringFromClass(self.class),self,self.contentType,self.contentLength,self.byteRangeAccessSupported];
}
@end
