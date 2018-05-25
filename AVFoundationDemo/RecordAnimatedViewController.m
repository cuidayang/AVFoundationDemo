//
//  RecordAnimatedViewController.m
//  AVFoundationDemo
//
//  Created by leoking870 on 2018/5/14.
//  Copyright © 2018年 leoking870. All rights reserved.
//

#import "RecordAnimatedViewController.h"
#import "KYVideoMVPreviewAnimatedView.h"
#import <Masonry.h>
#import <AVFoundation/AVFoundation.h>
@interface RecordAnimatedViewController ()<KYVideoMVPreviewAnimatedViewDelegate>
@property (nonatomic, strong) NSMutableArray *images;
@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic, strong) KYVideoMVPreviewAnimatedView *previewAnimatedView;
@end

@implementation RecordAnimatedViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    _previewAnimatedView = [[KYVideoMVPreviewAnimatedView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    _previewAnimatedView.displayDuration = 1;
    _previewAnimatedView.transitionDuration = 1;
    [self.view addSubview:_previewAnimatedView];
    [_previewAnimatedView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.top.trailing.equalTo(self.view);
        make.height.equalTo(self.view.mas_width);
    }];
    _previewAnimatedView.delegate = self;
    NSMutableArray *images = [NSMutableArray array];
    for (int i = 0; i < 5; ++i) {
        UIImage *image = [UIImage imageNamed:[NSString stringWithFormat:@"%d", i+1]];
        [images addObject:image];
    }
    _previewAnimatedView.images = images;
    
    _images = [NSMutableArray arrayWithCapacity:60 * 10];
}
- (void)kYVideoMVPreviewAnimatedViewImageDidLoadAllImages:(KYVideoMVPreviewAnimatedView *)kYVideoMVPreviewAnimatedView {
    [kYVideoMVPreviewAnimatedView play];
    _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(handleDisplayLink:)];
    _displayLink.preferredFramesPerSecond = 24;
    [_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)handleDisplayLink:(id)sender {
    
    
    if (_images.count < 240) {
        UIImage *image = [self.class imageFromView:self.previewAnimatedView];
        [_images addObject:image];
    }
    else {
        [self.displayLink invalidate];
        [self createVideoFromImages:self.images];
    }
}
+ (UIImage *)imageFromView:(UIView *)view
{
    UIGraphicsBeginImageContextWithOptions(view.frame.size , YES , 0 );
    
    if ([view respondsToSelector:@selector(drawViewHierarchyInRect:afterScreenUpdates:)]) {
        [view drawViewHierarchyInRect:view.bounds afterScreenUpdates:YES];
    } else {
        [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    }
    UIImage *rasterizedView = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return rasterizedView;
}


+ (NSString *) defaultCacheDirectory {
    NSArray<NSString *> *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    return paths.firstObject;
}
- (void)createVideoFromImages:(NSMutableArray *)images {
    
    
    NSString *path = [[self.class defaultCacheDirectory]stringByAppendingPathComponent:@"demo.mp4"];
    if ([[NSFileManager defaultManager]fileExistsAtPath:path]) {
        [[NSFileManager defaultManager]removeItemAtPath:path error:nil];
    }
    NSError *error = nil;
    AVAssetWriter *videoWriter = [[AVAssetWriter alloc]initWithURL:[NSURL fileURLWithPath:path] fileType:AVFileTypeMPEG4 error:&error];
    CGSize size = self.previewAnimatedView.frame.size;
    CGFloat width = ceil(size.width / 16) * 16;
    CGFloat height = ceil(size.height / 16) * 16;
    size = CGSizeMake(width, height);
    NSDictionary *videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:AVVideoCodecH264, AVVideoCodecKey, @(size.width), AVVideoWidthKey, @(size.height), AVVideoHeightKey, nil];
    
    
    AVAssetWriterInput *videoWriterInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];
    AVAssetWriterInputPixelBufferAdaptor *adaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:videoWriterInput sourcePixelBufferAttributes:nil];
    
    videoWriterInput.expectsMediaDataInRealTime = YES;
    [videoWriter addInput:videoWriterInput];
    
    [videoWriter startWriting];
    [videoWriter startSessionAtSourceTime:kCMTimeZero];
    
    CVPixelBufferRef buffer = NULL;
    int frameCount = 0;
    int kRecordingFPS = 24;
    int duration = 2;
    CMTime time = CMTimeMake(0, kRecordingFPS);
    for (UIImage *img in images) {
        buffer = [self.class pixelBufferFromCGImage:img.CGImage size:size];
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
            }
            else {
                printf("adaptor not ready %d, %d\n", frameCount, j);
                [NSThread sleepForTimeInterval:0.1];
            }
            j++;
        }
        time = CMTimeAdd(time, CMTimeMakeWithSeconds(1.0f/24.0f, kRecordingFPS));
        if (!appendOK) {
            printf("error appending image %d times %d\n", frameCount, j);
        }
    }
    
    [videoWriterInput markAsFinished];
    [videoWriter finishWritingWithCompletionHandler:^{
        //        [NSThread sleepForTimeInterval:1];
        
    }];
    NSLog(@"Write Ended");
}

+ (CVPixelBufferRef) pixelBufferFromCGImage:(CGImageRef)image size:(CGSize)size
{
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey,
                             nil];
    CVPixelBufferRef pxbuffer = NULL;
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, size.width,
                                          size.height, kCVPixelFormatType_32ARGB, (__bridge CFDictionaryRef) options,
                                          &pxbuffer);
    status=status;//Added to make the stupid compiler not show a stupid warning.
    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);
    
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    NSParameterAssert(pxdata != NULL);
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pxdata, size.width,
                                                 size.height, 8, 4*size.width, rgbColorSpace,
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
@end
