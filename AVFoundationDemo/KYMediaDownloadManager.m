//
//  KYMediaDownloadManager.m
//  Pods
//
//  Created by leoking870 on 2017/12/5.
//
//

#import "KYMediaDownloadManager.h"
#import <objc/runtime.h>
#import <MobileCoreServices/MobileCoreServices.h>
@interface AVAssetResourceLoadingRequest (Task)
@property (nonatomic, strong) NSURLSessionTask *task;
@property (nonatomic, strong) NSURL *location;
@property (nonatomic, strong) NSData *data;
@end

@implementation AVAssetResourceLoadingRequest (Task)
- (void)setTask:(NSURLSessionTask *)task {
    objc_setAssociatedObject(self, @selector(setTask:), task, OBJC_ASSOCIATION_RETAIN);
}

- (NSURLSessionTask *)task {
    return objc_getAssociatedObject(self, @selector(setTask:));
}

- (void)setLocation:(NSURL *)location {
    objc_setAssociatedObject(self, @selector(setLocation:), location, OBJC_ASSOCIATION_RETAIN);
}

- (NSURL *)location {
    return objc_getAssociatedObject(self, @selector(setLocation:));
}

- (void)setData:(NSData *)data {
    objc_setAssociatedObject(self, @selector(setData:), data, OBJC_ASSOCIATION_RETAIN);
}

- (NSData *)data {
    return objc_getAssociatedObject(self, @selector(setData:));
}

@end


@implementation KYMediaDownloadInfo;

@end

@interface KYMediaDownloadManager () <NSURLSessionDelegate>
@property(nonatomic, strong) NSURLSession *session;
@property(nonatomic, strong) NSMutableDictionary *loadingTasks;
@property(nonatomic, strong) NSMutableArray<AVAssetResourceLoadingRequest *> *loadingRequests;
@end



@implementation KYMediaDownloadManager

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static KYMediaDownloadManager *instance = nil;
    dispatch_once(&onceToken, ^{
        instance = [[KYMediaDownloadManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:[NSOperationQueue mainQueue]];

        _loadingTasks = [NSMutableDictionary dictionary];
        _loadingRequests = [NSMutableArray array];
    }
    return self;
}

- (NSArray<KYMediaDownloadInfo *> *)dowloadMediasForURL:(NSURL *)mediaURL {
    NSMutableArray *taskInfos = self.loadingTasks[mediaURL.absoluteString];
    return taskInfos;
}

- (void)cancleMediaDownload:(KYMediaDownloadInfo *)downloadInfo {
    NSMutableArray *taskInfos = self.loadingTasks[downloadInfo.mediaURL.absoluteString];
    [taskInfos removeObject:downloadInfo];
    if (taskInfos.count == 0) {
        [downloadInfo.task cancel];
        if (downloadInfo.cancle) {
            downloadInfo.cancle();
        }
    }
}

- (KYMediaDownloadInfo *)downloadMediaWithURL:(NSURL *)mediaURL progress:(void (^)(CGFloat progress))progress completion:(void (^)(NSURL *filePathURL, NSError *))completion {
    return [self downloadMediaWithURL:mediaURL progress:progress completion:completion cancle:nil];
}

- (KYMediaDownloadInfo *)downloadMediaWithURL:(NSURL *)mediaURL progress:(void (^)(CGFloat progress))progress completion:(void (^)(NSURL *filePathURL, NSError *error))completion cancle:(void (^)(void))cancle {
    NSMutableArray<KYMediaDownloadInfo *> *taskInfos = self.loadingTasks[mediaURL.absoluteString];
    if (taskInfos.count == 0) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:[KYMediaDownloadManager localURLForMediaURL:mediaURL].path]) {
            dispatch_async(dispatch_get_current_queue(), ^{
//                if (progress) {
//                    progress(1);
//                }
                if (completion) {
                    completion([KYMediaDownloadManager localURLForMediaURL:mediaURL], nil);
                }
            });
            return nil;
        } else {
            NSURLSessionTask *task = [self.session downloadTaskWithRequest:[NSURLRequest requestWithURL:mediaURL]];
            [task resume];
            taskInfos = [NSMutableArray array];
            KYMediaDownloadInfo *info = [[KYMediaDownloadInfo alloc] init];
            info.task = task;
            info.mediaURL = mediaURL;
            info.progress = progress;
            info.completion = completion;
            info.cancle = cancle;
            [taskInfos addObject:info];
            self.loadingTasks[mediaURL.absoluteString] = taskInfos;
            return info;
        }
    } else {
        KYMediaDownloadInfo *info = [[KYMediaDownloadInfo alloc] init];
        info.mediaURL = mediaURL;
        info.progress = progress;
        info.completion = completion;
        info.cancle = cancle;
        info.task = taskInfos.firstObject.task;

        [taskInfos addObject:info];
        return info;
    }
}
+ (NSString *)tf_pathForDirectory:(NSSearchPathDirectory)directory {
    return [NSSearchPathForDirectoriesInDomains(directory, NSUserDomainMask, YES) lastObject];
}

+ (NSURL *)localURLForMediaURL:(NSURL *)mediaURL {
    NSString *fileName = mediaURL.lastPathComponent;
    NSString *path = [[self tf_pathForDirectory:NSCachesDirectory] stringByAppendingPathComponent:fileName];
    return [NSURL fileURLWithPath:path];
}


- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location {
    NSLog(@"下载结束:%@ location:%@",downloadTask, location);
    if ([downloadTask.currentRequest.URL.absoluteString isEqualToString:downloadTask.originalRequest.URL.absoluteString]) {
        [[NSFileManager defaultManager] copyItemAtPath:location.path toPath:[KYMediaDownloadManager localURLForMediaURL:downloadTask.currentRequest.URL].path error:nil];
    }
}


- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    NSLog(@"下载Task:%@ didWriteData:%d, totalBytesWritten:%d, totalBytesExpectedToWrite:%d",downloadTask,  bytesWritten, totalBytesWritten, totalBytesExpectedToWrite);
    if ([downloadTask.currentRequest.URL.absoluteString isEqualToString:downloadTask.originalRequest.URL.absoluteString]) {
        if (totalBytesExpectedToWrite != NSURLSessionTransferSizeUnknown) {
            CGFloat progress = (CGFloat) (1.0 * totalBytesWritten / totalBytesExpectedToWrite);
            NSMutableArray *taskInfos = self.loadingTasks[downloadTask.currentRequest.URL.absoluteString];
            for (KYMediaDownloadInfo *downloadInfo in taskInfos) {
                downloadInfo.progress ? downloadInfo.progress(progress) : nil;
            }
        }

    }
}


- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    NSMutableArray *taskInfos = self.loadingTasks[task.currentRequest.URL.absoluteString];
    NSLog(@"下载完成:%@ ",task);
    if (!error && taskInfos) {
        NSLog(@"下载成功");
        for (KYMediaDownloadInfo *downloadInfo in taskInfos) {
            downloadInfo.completion([KYMediaDownloadManager localURLForMediaURL:task.currentRequest.URL], nil);
        }

    } else {
        
        taskInfos = self.loadingTasks[task.originalRequest.URL.absoluteString];
        if (!error) {
            error = [NSError errorWithDomain:@"KYNetworkingErrorDomain" code:300 userInfo:@{NSLocalizedFailureReasonErrorKey: @"资源不存在"}];
        }
        NSLog(@"下载失败:%@", error);
        for (KYMediaDownloadInfo *downloadInfo in taskInfos) {
            downloadInfo.completion(nil, error);
        }
    }
    self.loadingTasks[task.originalRequest.URL.absoluteString] = nil;
}

@end
