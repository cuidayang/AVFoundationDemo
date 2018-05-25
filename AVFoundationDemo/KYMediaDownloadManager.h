//
//  KYMediaDownloadManager.h
//  Pods
//
//  Created by leoking870 on 2017/12/5.
//
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
@import AVFoundation;
@interface KYMediaDownloadInfo : NSObject
@property (nonatomic, strong) NSString *identifier;
@property (nonatomic, strong) NSURL *mediaURL;
@property (nonatomic, strong) NSURLSessionTask *task;
@property (nonatomic, copy)void(^progress)(CGFloat progress);
@property (nonatomic, copy)void (^completion)(NSURL *filePathURL, NSError *error);
@property (nonatomic, copy)void (^cancle)(void);
@end


/**
 * 音视频下载管理
 */
@interface KYMediaDownloadManager : NSObject

+ (instancetype)sharedInstance;

/**
 下载资源: 同一链接资源,本地无文件时下载,有文件时返回该文件地址, 如果一个资源正在下载,那么不会发起两个请求

 @param mediaURL 目标链接
 @param progress 进程百分比(小数)
 @param completion 结束之后的回调(filePathURL:文件所在地址,error:是否错误)
 */
- (KYMediaDownloadInfo *)downloadMediaWithURL:(NSURL *)mediaURL
                    progress:(void(^)(CGFloat progress))progress
                  completion:(void(^)(NSURL *filePathURL, NSError *error))completion;

- (KYMediaDownloadInfo *)downloadMediaWithURL:(NSURL *)mediaURL
                                     progress:(void(^)(CGFloat progress))progress
                                   completion:(void(^)(NSURL *filePathURL, NSError *error))completion
                                       cancle:(void(^)(void))cancle;

- (NSArray<KYMediaDownloadInfo *> *)dowloadMediasForURL:(NSURL *)mediaURL;
/**
 取消目标链接下载(如果正在下载的话)

 @param downloadInfo 目标下载链接
 */
- (void)cancleMediaDownload:(KYMediaDownloadInfo *)downloadInfo;

+ (NSURL *)localURLForMediaURL:(NSURL *)mediaURL;
@end
