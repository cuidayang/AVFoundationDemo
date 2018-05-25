//
//  KYVideoMVPreviewAnimatedView.m
//  Pods
//
//  Created by leoking870 on 2017/11/16.
//
//

#import "KYVideoMVPreviewAnimatedView.h"
#import <SDWebImagePrefetcher.h>
#import <UIImageView+WebCache.h>
#import <NSString+YYAdd.h>

#import "NSArray+TFCore.h"
#import "UIImage+TFCore.h"

@interface KYVideoMVPreviewAnimatedView () <SDWebImagePrefetcherDelegate, CAAnimationDelegate>
@property(nonatomic, strong) SDWebImagePrefetcher *imagePrefetcher;
@property(nonatomic, strong) UIImageView *bcgImageView;
@property(nonatomic, strong) UIImageView *imageView;
@property(nonatomic, assign) BOOL playing;
@property(nonatomic) NSUInteger transitionIndex; // 当前动画类型索引
@property(nonatomic, strong) NSMutableArray *prefetchedURLs;
@property(nonatomic, strong) NSURL *currentImageURL;
@property(nonatomic, strong) UIImage *currentImage;
@property(nonatomic, assign, readwrite) KYVideoMVPreviewAnimatedViewState state;
@end


@implementation KYVideoMVPreviewAnimatedView


- (void)dealloc {
    [NSThread cancelPreviousPerformRequestsWithTarget:self];
    [self.imagePrefetcher cancelPrefetching];
    //清下内存
    [[[SDWebImageManager sharedManager] imageCache] clearMemory];
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.imagePrefetcher = [[SDWebImagePrefetcher alloc] init];
        self.imagePrefetcher.options = SDWebImageRetryFailed | SDWebImageHighPriority;
        self.imagePrefetcher.delegate = self;

        self.bcgImageView = [[UIImageView alloc] initWithFrame:self.bounds];
        self.bcgImageView.contentMode = UIViewContentModeScaleAspectFill;
        self.bcgImageView.clipsToBounds = YES;
        [self addSubview:self.bcgImageView];
        
        
        NSLayoutConstraint *leading = [self.bcgImageView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor];
        NSLayoutConstraint *top = [self.bcgImageView.topAnchor constraintEqualToAnchor:self.topAnchor];
        NSLayoutConstraint *trailing = [self.bcgImageView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor];
        NSLayoutConstraint *bottom = [self.bcgImageView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor];
        [NSLayoutConstraint activateConstraints:@[leading,top, trailing, bottom]];

        self.imageView = [[UIImageView alloc] initWithFrame:self.bounds];
        self.imageView.contentMode = UIViewContentModeScaleAspectFit;
        [self addSubview:self.imageView];
        
        leading = [self.imageView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor];
        top = [self.imageView.topAnchor constraintEqualToAnchor:self.topAnchor];
        trailing = [self.imageView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor];
        bottom = [self.imageView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor];
        [NSLayoutConstraint activateConstraints:@[leading,top, trailing, bottom]];
        
        
        self.clipsToBounds = YES;
        self.prefetchedURLs = [NSMutableArray array];
        self.displayDuration = 3.8;
        self.transitionDuration = 2;
        self.state = KYVideoMVPreviewAnimatedViewStateNone;
    }
    return self;
}

- (void)setImageURLs:(NSArray<NSURL *> *)imageURLs {
    if ([imageURLs.firstObject isKindOfClass:[NSString class]]) {
        _imageURLs = [imageURLs tf_mapUsingBlock:^id(id obj, NSInteger idx) {
            return [NSURL URLWithString:obj];
        }];
    } else {
        _imageURLs = imageURLs;
    }
    if (imageURLs.count == 0) {
        self.state = KYVideoMVPreviewAnimatedViewStateNoMediaData;
        self.error = [NSError errorWithDomain:@"KYNetworkingErrorDomain" code:10001 userInfo:@{NSLocalizedFailureReasonErrorKey: @"图片数量为0"}];
        if ([self.delegate respondsToSelector:@selector(kYVideoMVPreviewAnimatedViewImageDidLoadFailed:error:)]) {
            [self.delegate kYVideoMVPreviewAnimatedViewImageDidLoadFailed:self error:self.error];
        }
    } else {
        [self startLoad];
    }
}

- (void)setImages:(NSArray<UIImage *> *)images {
    if (images.count == 0) {
        self.state = KYVideoMVPreviewAnimatedViewStateNoMediaData;
        self.error = [NSError errorWithDomain:@"KYNetworkingErrorDomain" code:10001 userInfo:@{NSLocalizedFailureReasonErrorKey: @"图片数量为0"}];
        if ([self.delegate respondsToSelector:@selector(kYVideoMVPreviewAnimatedViewImageDidLoadFailed:error:)]) {
            [self.delegate kYVideoMVPreviewAnimatedViewImageDidLoadFailed:self error:self.error];
        }
        return;
    }
    self.state = KYVideoMVPreviewAnimatedViewStateLoading;
    _images = images;
    [self updateImageViewByImage:images.firstObject];
    self.currentImage = images.firstObject;
    self.bcgImageView.image = [self.currentImage tf_blurImageWithType:TFImageBlurTypeLight];
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(kYVideoMVPreviewAnimatedView:loadProgress:)]) {
            [self.delegate kYVideoMVPreviewAnimatedView:self loadProgress:1];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            self.state = KYVideoMVPreviewAnimatedViewStateReadyToPlay;
            if ([self.delegate respondsToSelector:@selector(kYVideoMVPreviewAnimatedViewImageDidLoadAllImages:)]) {
                [self.delegate kYVideoMVPreviewAnimatedViewImageDidLoadAllImages:self];
            }
        });
    });
}

- (void)startLoad {
    self.state = KYVideoMVPreviewAnimatedViewStateLoading;
    self.error = nil;
    [self.imagePrefetcher cancelPrefetching];
    [self.prefetchedURLs removeAllObjects];

    [self.imagePrefetcher prefetchURLs:_imageURLs];
    self.imageView.image = self.placeholderImage;
    self.bcgImageView.image = [self.placeholderImage tf_blurImageWithType:TFImageBlurTypeLight];
}

- (void)setPlaceholderImage:(UIImage *)placeholderImage {
    _placeholderImage = placeholderImage;
    if (!self.playing) {
        self.imageView.image = placeholderImage;
        self.bcgImageView.image = [self.placeholderImage tf_blurImageWithType:TFImageBlurTypeLight];
    }
}

- (void)play {
    if (self.playing) {
        return;
    }
    if (self.state == KYVideoMVPreviewAnimatedViewStatePausing) {
        [self resume];
        return;
    }
    self.playing = YES;
    self.state = KYVideoMVPreviewAnimatedViewStatePlaying;
    if (self.imageURLs) {
        [self updateCurrentImageWithURL:[self nextImageURL] ?: self.imageURLs.firstObject];
        [self performSelector:@selector(displayNextImage) withObject:nil afterDelay:self.displayDuration];
    } else {
        [self performSelector:@selector(displayNextImage) withObject:nil afterDelay:self.displayDuration];
    }
}


- (void)pause {
    self.playing = NO;
    self.state = KYVideoMVPreviewAnimatedViewStatePausing;
    [NSThread cancelPreviousPerformRequestsWithTarget:self];
}

- (void)resume {
    self.playing = YES;
    self.state = KYVideoMVPreviewAnimatedViewStatePlaying;
    [self performSelector:@selector(displayNextImage) withObject:nil afterDelay:self.displayDuration];
}

- (void)displayNextImage {
    if (self.imageURLs.count) {
        NSURL *url = [self nextImageURL];
        if (!url) {
            return;
        }
        [self updateCurrentImageWithURL:url];
        [self addRandomTransitionToImageView];
        [self performSelector:@selector(displayNextImage) withObject:nil afterDelay:self.displayDuration];
    } else {
        UIImage *image = [self nextImage];
        if (!image) {
            return;
        }
        [self updateImageViewByImage:image];
        self.currentImage = image;
        self.bcgImageView.image = [image tf_blurImageWithType:TFImageBlurTypeLight];

        [self addRandomTransitionToImageView];
        [self performSelector:@selector(displayNextImage) withObject:nil afterDelay:self.displayDuration];
    }
}

- (void)addRandomTransitionToImageView {
    static NSArray *transitionTypes = nil;
    static NSArray *transitionSubtypes = nil;
    //NSLog(@"显示图片动画");
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *effect1 = [NSString stringWithBase64EncodedString:@"cGFnZUN1cmw="];//pageCurl
        NSString *effect2 = [NSString stringWithBase64EncodedString:@"cGFnZVVuQ3VybA=="];//pageUnCurl
        NSString *effect3 = [NSString stringWithBase64EncodedString:@"Y3ViZQ=="];
        NSString *effect4 = [NSString stringWithBase64EncodedString:@"b2dsRmxpcA=="];
        NSString *effect5 = [NSString stringWithBase64EncodedString:@"cmlwcGxlRWZmZWN0"];//rippleEffect
        NSString *effect6 = [NSString stringWithBase64EncodedString:@"c3Vja0VmZmVjdA=="];//suckEffect
        if (YES) {
            transitionTypes = @[
                    effect1,//1
                    kCATransitionFade,//2
                    kCATransitionMoveIn,//3
                    kCATransitionReveal,//4
                    effect2,//5
                    effect3,//6
                    effect4,//8
                    effect3,//7
                    effect4,//9
                    effect5,//10
                    effect6,//11
            ];
        } else {
            transitionTypes = @[kCATransitionFade, kCATransitionMoveIn, kCATransitionPush, kCATransitionReveal, kCATransitionFade];
        }
        transitionSubtypes = @[
                kCATransitionFromLeft,//1
                kCATransitionFromLeft,//2
                kCATransitionFromRight,//3
                kCATransitionFromLeft,//4
                kCATransitionFromLeft,//5
                kCATransitionFromRight,//6
                kCATransitionFromTop,//8
                kCATransitionFromLeft,//7
                kCATransitionFromBottom,//9
                kCATransitionFromLeft,//10
                kCATransitionFromLeft,
        ];
    });

    CATransition *transition = [CATransition animation];
    transition.duration = self.transitionDuration;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    transition.type = transitionTypes[self.transitionIndex];
    transition.subtype = transitionSubtypes[self.transitionIndex];
    transition.delegate = self;
    [self.imageView.layer addAnimation:transition forKey:nil];

    CATransition *bcgT = [CATransition animation];
    bcgT.duration = self.transitionDuration;
    bcgT.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    bcgT.type = kCATransitionFade;
    bcgT.subtype = kCATransitionFromLeft;
    bcgT.delegate = self;
    [self.bcgImageView.layer addAnimation:bcgT forKey:nil];
    self.transitionIndex = (self.transitionIndex + 1) % transitionTypes.count;
}

#pragma mark - CAAnimationDelegate

- (void)animationDidStart:(CAAnimation *)anim {

}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {

}

- (UIImage *)nextImage {
    if (self.images.count > 0) {
        NSUInteger index = 0;
        if (self.currentImage) {
            index = [self.images indexOfObject:self.currentImage];
            index = (index + 1) % self.images.count;
        }
        return self.images[index];
    }
    return nil;
}

- (NSURL *)nextImageURL {
    if (_prefetchedURLs.count > 0) {
        NSUInteger index = 0;
        if (self.currentImageURL) {
            for (NSUInteger i = 0; i < self.prefetchedURLs.count; ++i) {
                NSURL *prefetchedURL = self.prefetchedURLs[i];
                if (self.currentImageURL == prefetchedURL) {
                    index = i;
                    break;
                }
            }
            index = (index + 1) % self.prefetchedURLs.count;
        }
        return self.prefetchedURLs[index];
    }
    return nil;
}

- (void)updateCurrentImageWithURL:(NSURL *)url {
    if (!url) {
        return;
    }
    NSString *imageKey = [[SDWebImageManager sharedManager] cacheKeyForURL:url];
    UIImage *image = [[[SDWebImageManager sharedManager] imageCache] imageFromCacheForKey:imageKey];
    if (image) {
        [self updateImageViewByImage:image];

        self.bcgImageView.image = [image tf_blurImageWithType:TFImageBlurTypeLight];
        self.currentImageURL = url;
    } else {
        [self.imageView sd_setImageWithURL:url completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
            if (image) {
                [UIView transitionWithView:self.imageView duration:0.3 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
                    [self updateImageViewByImage:image];
                    self.bcgImageView.image = [image tf_blurImageWithType:TFImageBlurTypeLight];
                    self.currentImageURL = url;
                }               completion:^(BOOL finished) {

                }];
            } else {
                NSLog(@"下载图片失败:%@", error.localizedFailureReason);
            }
        }];
    }
}

- (void)updateImageViewByImage:(UIImage *)image {
//    if (image.size.width > image.size.height + 1) {
//        [self.imageView mas_remakeConstraints:^(MASConstraintMaker *make) {
//            make.center.equalTo(self);
//            make.width.equalTo(self.mas_width);
//            make.height.equalTo(self.mas_width).multipliedBy(image.size.height / image.size.width);
//        }];
//
//    } else if (image.size.width < image.size.height - 1) {
//        [self.imageView mas_remakeConstraints:^(MASConstraintMaker *make) {
//            make.center.equalTo(self);
//            make.height.equalTo(self.mas_height);
//            make.width.equalTo(self.mas_height).multipliedBy(image.size.width / image.size.height);
//        }];
//    } else {
//        [self.imageView mas_remakeConstraints:^(MASConstraintMaker *make) {
//            make.center.equalTo(self);
//            make.width.equalTo(self.mas_width);
//            make.height.equalTo(self.imageView.mas_width);
//        }];
//    }
    [self layoutIfNeeded];
    self.imageView.image = image;
}

#pragma mark - SDWebImagePrefetcherDelegate

/**
 * 不管成功还是失败, 结束了一个就会回调此函数
 */
- (void)imagePrefetcher:(nonnull SDWebImagePrefetcher *)imagePrefetcher
         didPrefetchURL:(nullable NSURL *)imageURL
          finishedCount:(NSUInteger)finishedCount
             totalCount:(NSUInteger)totalCount {
    /**
     *  已下载图片 URL 存储相对顺序与全部 URL 数组中 URL 顺序保持一致
     */
    [self.imagePrefetcher.manager cachedImageExistsForURL:imageURL completion:^(BOOL isInCache) {
        if (isInCache) {
            NSLog(@"缓存图片成功:%@", imageURL);
            if (self.prefetchedURLs.count == 0 && [self.delegate respondsToSelector:@selector(kYVideoMVPreviewAnimatedViewImageDidLoaded:)]) {
                //通知外面, 已经有一张图片加载了
                [self.delegate kYVideoMVPreviewAnimatedViewImageDidLoaded:self];
            }
            NSUInteger insertionIndex = [self.prefetchedURLs indexOfObject:imageURL
                                                             inSortedRange:NSMakeRange(0, self.prefetchedURLs.count)
                                                                   options:NSBinarySearchingInsertionIndex
                                                           usingComparator:^(NSURL *URL1, NSURL *URL2) {
                                                               return [@([self.imageURLs indexOfObject:URL1]) compare:@([self.imageURLs indexOfObject:URL2])];
                                                           }];
            [self.prefetchedURLs insertObject:imageURL atIndex:insertionIndex];
            if ([imageURL isEqual:self.imageURLs.firstObject]) {
                [self.imageView sd_setImageWithURL:imageURL];
            }
            if ([self.delegate respondsToSelector:@selector(kYVideoMVPreviewAnimatedView:loadProgress:)]) {
                [self.delegate kYVideoMVPreviewAnimatedView:self loadProgress:self.prefetchedURLs.count * 1.0f / self.imageURLs.count];
            }
        } else {
            NSLog(@"缓存图片失败:%@", imageURL);
        }
    }];
}

- (CGFloat)progress {
    if (self.images.count) {
        return 1;
    } else if (self.imageURLs.count) {
        return self.prefetchedURLs.count * 1.0f / self.imageURLs.count;
    }
    return 1;
}


- (void)imagePrefetcher:(nonnull SDWebImagePrefetcher *)imagePrefetcher
didFinishWithTotalCount:(NSUInteger)totalCount//(total - self.skippedCount)
           skippedCount:(NSUInteger)skippedCount {
    NSLog(@"缓存图片结束,成功:%d, 失败:%d", totalCount, skippedCount);
    //全部都下载成功了
    if (totalCount > 0 && skippedCount == 0) {
        self.state = KYVideoMVPreviewAnimatedViewStateReadyToPlay;
        if ([self.delegate respondsToSelector:@selector(kYVideoMVPreviewAnimatedViewImageDidLoadAllImages:)]) {
            [self.delegate kYVideoMVPreviewAnimatedViewImageDidLoadAllImages:self];
        }
    }

    if (skippedCount > 0) {
        if (totalCount == 0) {
            //全部都下载失败了
            self.error = [NSError errorWithDomain:@"KYNetworkingErrorDomain" code:10000 userInfo:@{NSLocalizedFailureReasonErrorKey: @"图片加载失败"}];
            self.state = KYVideoMVPreviewAnimatedViewStateError;
            if ([self.delegate respondsToSelector:@selector(kYVideoMVPreviewAnimatedViewImageDidLoadFailed:error:)]) {
                [self.delegate kYVideoMVPreviewAnimatedViewImageDidLoadFailed:self error:self.error];
            }
        } else {
            //有成功的, 那就再试试
            [self prefetchFailedURLs];
        }
    }
}

- (void)prefetchFailedURLs {
    NSMutableArray *failedURLs = [NSMutableArray array];
    dispatch_group_t group = dispatch_group_create();

    for (NSURL *imageURL in self.imageURLs) {
        dispatch_group_enter(group);
        [self.imagePrefetcher.manager cachedImageExistsForURL:imageURL completion:^(BOOL isInCache) {
            if (!isInCache) {
                [failedURLs addObject:imageURL];
            }
            dispatch_group_leave(group);
        }];
    }

    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        [self.imagePrefetcher prefetchURLs:[failedURLs copy]];
    });
}


- (BOOL)loadSuccess {
    return self.state == KYVideoMVPreviewAnimatedViewStateReadyToPlay || self.state == KYVideoMVPreviewAnimatedViewStatePlaying || self.state == KYVideoMVPreviewAnimatedViewStatePausing;
}

- (BOOL)loadFailed {
    return self.state == KYVideoMVPreviewAnimatedViewStateError || self.state == KYVideoMVPreviewAnimatedViewStateNoMediaData;
}


@end
