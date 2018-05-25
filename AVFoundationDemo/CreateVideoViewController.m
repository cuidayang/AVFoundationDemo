//
//  CreateVideoViewController.m
//  AVFoundationDemo
//
//  Created by leoking870 on 2018/5/11.
//  Copyright © 2018年 leoking870. All rights reserved.
//

#import "CreateVideoViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "KYMediaPlayerView.h"
#import "APLCompositionDebugView.h"
#import "AVFoundationUtils.h"
#import "AssetBrowserController.h"
#import "KYVideoProgressView.h"
@interface CreateVideoViewController () <UITableViewDelegate, UITableViewDataSource,AssetBrowserControllerDelegate>
@property(weak, nonatomic) IBOutlet KYMediaPlayerView *mediaPlayer;
@property(nonatomic, assign) NSUInteger transitionIndex;
@property(nonatomic, strong) NSMutableArray *layers;
@property(nonatomic, strong) UIImageView *imageView;
@property(weak, nonatomic) IBOutlet UITableView *tableView;
@property(nonatomic, strong) NSArray *videos;
@property (weak, nonatomic) IBOutlet APLCompositionDebugView *debugView;
@property (nonatomic, retain) AVMutableComposition *composition;
@property (nonatomic, retain) AVMutableVideoComposition *videoComposition;

@property (nonatomic, strong) NSMutableArray *selectedURLs;

@end

@implementation CreateVideoViewController
+ (NSString *)defaultCacheDirectory {
    NSArray<NSString *> *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    return paths.firstObject;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    _selectedURLs = [NSMutableArray array];
    CGSize size = self.view.frame.size;
    CGFloat width = ceil(size.width / 16) * 16;
    CGFloat height = ceil(size.height / 16) * 16;
    size = CGSizeMake(width, height);
    _layers = [NSMutableArray arrayWithCapacity:6];
    for (int i = 0; i < 6; ++i) {
        UIImage *image = [UIImage imageNamed:[NSString stringWithFormat:@"%d", i + 1]];
        CALayer *overlayLayer2 = [CALayer layer];
        [overlayLayer2 setContents:(__bridge id) [image CGImage]];
        overlayLayer2.frame = CGRectMake(0, 0, size.width, size.height);
        [overlayLayer2 setMasksToBounds:YES];
        [_layers addObject:overlayLayer2];
    }
    _transitionIndex = 5;
    self.imageView = [[UIImageView alloc] init];
    [self.view addSubview:self.imageView];
    self.imageView.frame = CGRectMake(self.view.frame.size.width, 0, self.view.frame.size.width, self.view.frame.size.height);
    
    [self reloadData];
    
    UIBarButtonItem *addItem = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(onAddItemTapped:)];
    self.navigationItem.rightBarButtonItem = addItem;
}

- (void)onAddItemTapped:(id)sender {
    AssetBrowserController *controller = [[AssetBrowserController alloc]initWithSourceType:AssetBrowserSourceTypeCameraRoll modalPresentation:YES];
    controller.delegate = self;
    UINavigationController *nav = [[UINavigationController alloc]initWithRootViewController:controller];
    [self.navigationController presentViewController:nav animated:YES completion:nil];
}

- (void)assetBrowser:(AssetBrowserController *)assetBrowser didChooseItem:(AssetBrowserItem *)assetBrowserItem {
    [self.navigationController dismissViewControllerAnimated:YES completion:^{
        self.videos = [self.videos arrayByAddingObject:assetBrowserItem.URL];
        [self.tableView reloadData];
    }];
}

- (void)assetBrowserDidCancel:(AssetBrowserController *)assetBrowser {
    [self.navigationController dismissViewControllerAnimated:YES completion:^{
        
    }];
}

- (void)reloadData {
    NSDirectoryEnumerator<NSURL *> *directoryEnumerator = [[NSFileManager defaultManager] enumeratorAtURL:[NSURL fileURLWithPath:[self.class defaultCacheDirectory]]
                                                                               includingPropertiesForKeys:@[NSURLNameKey, NSURLIsDirectoryKey]
                                                                                                  options:NSDirectoryEnumerationSkipsHiddenFiles
                                                                                             errorHandler:nil];
    NSMutableArray<NSURL *> *mutableFileURLs = [NSMutableArray array];
    
    for (NSURL *fileURL in directoryEnumerator) {
        if ([fileURL.path hasSuffix:@"mp4"]) {
            [mutableFileURLs addObject:fileURL];
        }
    }
    self.videos = [mutableFileURLs copy];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.videos.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    }
    NSURL *url = self.videos[indexPath.row];
    cell.textLabel.text = url.lastPathComponent;
    if ([self.selectedURLs containsObject:url]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    return cell;
}



- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleDelete;
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    return @"删除";
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSURL *url = self.videos[indexPath.row];
        [[NSFileManager defaultManager] removeItemAtURL:url error:nil];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self reloadData];
            [self.tableView reloadData];
        });
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSURL *url = self.videos[indexPath.row];
    if ([self.selectedURLs containsObject:url]) {
        [self.selectedURLs removeObject:url];
    }
    else {
        [self.selectedURLs addObject:url];
    }
    [self.tableView reloadData];
    
    
}

- (IBAction)toggleDebugViewVisible:(id)sender {
    self.debugView.hidden = !self.debugView.hidden;
    self.debugView.player = self.mediaPlayer.avPlayer;
    [self.debugView synchronizeToComposition:self.composition videoComposition:self.videoComposition audioMix:nil];
    [self.debugView setNeedsDisplay];
}

- (IBAction)manipulateURL:(id)sender {
    if (self.selectedURLs.count == 0) {
        return;
    }
    NSURL *url = self.selectedURLs.firstObject;
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"选择动画" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *action1 = [UIAlertAction actionWithTitle:@"播放" style:UIAlertActionStyleDefault handler:^(UIAlertAction *_Nonnull action) {
        self.mediaPlayer.mediaURL = url;
        self.mediaPlayer.videoGravity = AVLayerVideoGravityResizeAspect;
        self.mediaPlayer.delegate = self;
        self.mediaPlayer.playWhileDownload = YES;
        
        self.mediaPlayer.autoplay = YES;
        [self.mediaPlayer startLoad];
    }];
    [alertController addAction:action1];
    
    UIAlertAction *action3 = [UIAlertAction actionWithTitle:@"模糊" style:UIAlertActionStyleDefault handler:^(UIAlertAction *_Nonnull action) {
//        KYVideoProgressView *view = [KYVideoProgressView showProgressViewWithMessage:@"正在处理\n请勿锁屏或退出应用"];
        [AVFoundationUtils blurVideoWithURL:url radius:10 result:^(AVAsset *asset, AVVideoComposition *videoComposition) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [AVFoundationUtils exportComposition:asset videoComposition:videoComposition progress:^(CGFloat p) {
                    NSLog(@"p:%f",p);
                } completion:^(NSURL *url, NSError *e) {
                    dispatch_async(dispatch_get_main_queue(), ^{
//                        [view dismiss];
                        [self reloadData];
                        [self.tableView reloadData];
                    });
                }];
//                self.composition = asset;
//                self.videoComposition = videoComposition;
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:self.composition];
//                    playerItem.videoComposition = self.videoComposition;
//                    [self.mediaPlayer startLoadWithPlayerItem:playerItem];
//                });
            });
        }];
        
        
//        KYVideoProgressView *view = [KYVideoProgressView showProgressViewWithMessage:@"正在处理\n请勿锁屏或退出应用"];
//        [AVFoundationUtils blurVideoWithURL:url radius:10 progress:^(CGFloat p){
//            dispatch_async(dispatch_get_main_queue(), ^{
//                view.progress = p;
//            });
//        } completion:^(NSURL *url, NSError *error) {
//
//            NSLog(@"视频模糊成功:%@", url);
//            dispatch_async(dispatch_get_main_queue(), ^{
//                [view dismiss];
//                [self reloadData];
//                [self.tableView reloadData];
//            });
//        }];
    }];
    [alertController addAction:action3];
    
    UIAlertAction *action7 = [UIAlertAction actionWithTitle:@"GPU模糊" style:UIAlertActionStyleDefault handler:^(UIAlertAction *_Nonnull action) {
        KYVideoProgressView *view = [KYVideoProgressView showProgressViewWithMessage:@"正在处理\n请勿锁屏或退出应用"];
        [AVFoundationUtils gpuBlurVideoWithURL:url
                                        radius:10
                                      progress:^(CGFloat p){
                                          dispatch_async(dispatch_get_main_queue(), ^{
                                              view.progress = p;
                                          });
                                      }
                                    completion:^(NSURL *url, NSError *err) {
                                        NSLog(@"GPU视频模糊成功:%@", url);
                                        dispatch_async(dispatch_get_main_queue(), ^{
                                            [view dismiss];
                                            [self reloadData];
                                            [self.tableView reloadData];
                                        });
                                    }];
    }];
    [alertController addAction:action7];
    
    UIAlertAction *action4 = [UIAlertAction actionWithTitle:@"视频叠加" style:UIAlertActionStyleDefault handler:^(UIAlertAction *_Nonnull action) {
        
        [AVFoundationUtils overlayVideo:self.selectedURLs.firstObject position:CGPointMake(800, 800) size:CGSizeMake(480, 480) aboveVideo:self.selectedURLs.lastObject backgroundSize:CGSizeMake(1280, 1280) compositions:^(AVMutableComposition *composition, AVMutableVideoComposition *videoComposition) {
            self.composition = composition;
            self.videoComposition = videoComposition;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:self.composition];
                playerItem.videoComposition = self.videoComposition;
                [self.mediaPlayer startLoadWithPlayerItem:playerItem];
            });
        }];
        
//        [AVFoundationUtils overlayVideo:self.selectedURLs.firstObject onVideo:self.selectedURLs.lastObject targetSize:CGSizeMake(1280, 1280) compositions:^(AVMutableComposition *composition, AVMutableVideoComposition *videoComposition) {
//
//
//        }];
    }];
    [alertController addAction:action4];
    
    UIAlertAction *action11 = [UIAlertAction actionWithTitle:@"视频合并(one track)" style:UIAlertActionStyleDefault handler:^(UIAlertAction *_Nonnull action) {
        
        [AVFoundationUtils mergeVideosWithoutAnimation:self.selectedURLs
                                         separateTrack:NO
                                          compositions:^(AVMutableComposition *composition, AVMutableVideoComposition *videoComposition) {
            self.composition = composition;
            self.videoComposition = videoComposition;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:self.composition];
                playerItem.videoComposition = nil;
                [self.mediaPlayer startLoadWithPlayerItem:playerItem];
            });
        }];
    }];
    [alertController addAction:action11];
    
    UIAlertAction *action15 = [UIAlertAction actionWithTitle:@"视频合并(one track+ overlap)" style:UIAlertActionStyleDefault handler:^(UIAlertAction *_Nonnull action) {
        
        [AVFoundationUtils mergeVideosWronglyWithoutAnimation:self.selectedURLs
                                                      overlap:YES
                                          compositions:^(AVMutableComposition *composition, AVMutableVideoComposition *videoComposition) {
                                              self.composition = composition;
                                              self.videoComposition = videoComposition;
                                              
                                              dispatch_async(dispatch_get_main_queue(), ^{
                                                  AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:self.composition];
                                                  playerItem.videoComposition = nil;
                                                  [self.mediaPlayer startLoadWithPlayerItem:playerItem];
                                              });
                                          }];
    }];
    [alertController addAction:action15];
    
    UIAlertAction *action16 = [UIAlertAction actionWithTitle:@"视频合并(one track+ space)" style:UIAlertActionStyleDefault handler:^(UIAlertAction *_Nonnull action) {
        
        [AVFoundationUtils mergeVideosWronglyWithoutAnimation:self.selectedURLs
                                                      overlap:NO
                                                 compositions:^(AVMutableComposition *composition, AVMutableVideoComposition *videoComposition) {
                                                     self.composition = composition;
                                                     self.videoComposition = videoComposition;
                                                     
                                                     dispatch_async(dispatch_get_main_queue(), ^{
                                                         AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:self.composition];
                                                         playerItem.videoComposition = nil;
                                                         [self.mediaPlayer startLoadWithPlayerItem:playerItem];
                                                     });
                                                 }];
    }];
    [alertController addAction:action16];
    
    UIAlertAction *action22 = [UIAlertAction actionWithTitle:@"视频合并(separate track)" style:UIAlertActionStyleDefault handler:^(UIAlertAction *_Nonnull action) {
        
        [AVFoundationUtils mergeVideosWithoutAnimation:self.selectedURLs
                                         separateTrack:YES
                                          compositions:^(AVMutableComposition *composition, AVMutableVideoComposition *videoComposition) {
                                              self.composition = composition;
                                              self.videoComposition = videoComposition;
                                              
                                              dispatch_async(dispatch_get_main_queue(), ^{
                                                  AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:self.composition];
                                                  playerItem.videoComposition = nil;
                                                  [self.mediaPlayer startLoadWithPlayerItem:playerItem];
                                              });
                                          }];
    }];
    [alertController addAction:action22];
    
    UIAlertAction *action12 = [UIAlertAction actionWithTitle:@"视频合并+过渡动画" style:UIAlertActionStyleDefault handler:^(UIAlertAction *_Nonnull action) {
        
        [AVFoundationUtils mergeVideos:self.selectedURLs
                          compositions:^(AVMutableComposition *composition, AVMutableVideoComposition *videoComposition) {
            self.composition = composition;
            self.videoComposition = videoComposition;

            
            
            
            dispatch_async(dispatch_get_main_queue(), ^{
                AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:self.composition];
                playerItem.videoComposition = videoComposition;
                [self.mediaPlayer startLoadWithPlayerItem:playerItem];
            });
        }];
    }];
    [alertController addAction:action12];
    
    UIAlertAction *action6 = [UIAlertAction actionWithTitle:@"修改大小+模糊+叠加+LivePhoto" style:UIAlertActionStyleDefault handler:^(UIAlertAction *_Nonnull action) {
        NSDate *methodStart = [NSDate date];
        [AVFoundationUtils resizeVideoWithURL:url targetSize:CGSizeMake(90, 160) resizeMode:0 progress:nil completion:^(NSURL *url, NSError *error) {
            NSLog(@"修改大小成功:%@", url);
            [AVFoundationUtils gpuBlurVideoWithURL:url
                                            radius:10
                                          progress:nil completion:^(NSURL *url, NSError *error) {
                NSLog(@"视频模糊成功:%@", url);
                [AVFoundationUtils overlayVideo:url onVideo:url targetSize:CGSizeMake(540, 960) progress:nil completion:^(NSURL *url, NSError *error) {
                    NSLog(@"视频叠加成功:%@", url);
                    [AVFoundationUtils saveVideoToAlubmAsLivePhotoWithURL:url completion:^(NSError *error) {
                        NSDate *methodFinish = [NSDate date];
                        NSTimeInterval executionTime = [methodFinish timeIntervalSinceDate:methodStart];
                        NSLog(@"executionTime = %f", executionTime);
                        if (!error) {
                            NSLog(@"视频转LivePhoto成功");
                        } else {
                            NSLog(@"视频转LivePhoto失败:%@", error);
                        }
                    }];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self reloadData];
                        [self.tableView reloadData];
                    });
                }];
            }];
        }];
        
    }];
    [alertController addAction:action6];
    
    UIAlertAction *action8 = [UIAlertAction actionWithTitle:@"视频转LivePhoto" style:UIAlertActionStyleDefault handler:^(UIAlertAction *_Nonnull action) {
        
        [AVFoundationUtils saveVideoToAlubmAsLivePhotoWithURL:url completion:^(NSError *error) {
            if (!error) {
                NSLog(@"视频转LivePhoto成功");
            } else {
                NSLog(@"视频转LivePhoto失败:%@", error);
            }
        }];
    }];
    [alertController addAction:action8];
    
    UIAlertAction *action5 = [UIAlertAction actionWithTitle:@"修改视频大小" style:UIAlertActionStyleDefault handler:^(UIAlertAction *_Nonnull action) {
        [AVFoundationUtils resizeVideoWithURL:url targetSize:CGSizeMake(90, 160) resizeMode:0 progress:nil completion:^(NSURL *url, NSError *error) {
            NSLog(@"修改大小成功:%@", url);
            dispatch_async(dispatch_get_main_queue(), ^{
                [self reloadData];
                [self.tableView reloadData];
            });
        }];
    }];
    [alertController addAction:action5];
    
    
    
    UIAlertAction *cancle = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction *_Nonnull action) {
        
    }];
    [alertController addAction:cancle];
    alertController.popoverPresentationController.sourceView = sender;
    alertController.popoverPresentationController.sourceRect = [sender frame];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (IBAction)mergeVideos:(id)sender {
    NSMutableArray *files = [NSMutableArray arrayWithCapacity:5];
    
    for (int i = 1; i < 6; ++i) {
        NSURL *url2 = [AVFoundationUtils generateVideoFromImage:[UIImage imageNamed:[NSString stringWithFormat:@"%d", i]] targetSize:CGSizeMake(720, 1280) duration:7];
        [files addObject:url2];
    }
    
    [AVFoundationUtils mergeVideos:files compositions:^(AVMutableComposition *composition, AVMutableVideoComposition *videoComposition) {
        self.composition = composition;
        self.videoComposition = videoComposition;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            KYVideoProgressView *view = [KYVideoProgressView showProgressViewWithMessage:@"正在处理\n请勿锁屏或退出应用"];
            [AVFoundationUtils exportComposition:composition videoComposition:videoComposition progress:^(CGFloat p) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    view.progress = p;
                });
            } completion:^(NSURL *url, NSError *e) {
                
                for (NSURL *url in files) {
                    [[NSFileManager defaultManager]removeItemAtURL:url error:nil];
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    [view dismiss];
                    self.mediaPlayer.mediaURL = url;
                    self.mediaPlayer.videoGravity = AVLayerVideoGravityResizeAspect;
                    self.mediaPlayer.delegate = self;
                    self.mediaPlayer.playWhileDownload = YES;
                    
                    self.mediaPlayer.autoplay = YES;
                    [self.mediaPlayer startLoad];
                });
            }];
        });
        
//        dispatch_async(dispatch_get_main_queue(), ^{
//            AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:self.composition];
//            playerItem.videoComposition = nil;
//            [self.mediaPlayer startLoadWithPlayerItem:playerItem];
//

//        });
    }];
}
- (IBAction)mergeVideoWrong:(id)sender {
    NSMutableArray *files = [NSMutableArray arrayWithCapacity:5];
    
    for (int i = 1; i < 6; ++i) {
        NSURL *url2 = [AVFoundationUtils generateVideoFromImage:[UIImage imageNamed:[NSString stringWithFormat:@"%d", i]] targetSize:CGSizeMake(720, 1280) duration:7];
        [files addObject:url2];
    }
    [AVFoundationUtils mergeVideos:files compositions:^(AVMutableComposition *composition, AVMutableVideoComposition *videoComposition) {
        self.composition = composition;
        self.videoComposition = videoComposition;
        NSLog(@"文件:%@", files);
        dispatch_async(dispatch_get_main_queue(), ^{
            KYVideoProgressView *view = [KYVideoProgressView showProgressViewWithMessage:@"正在处理\n请勿锁屏或退出应用"];
            [AVFoundationUtils exportComposition:composition videoComposition:videoComposition progress:^(CGFloat p) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    view.progress = p;
                });
            } completion:^(NSURL *url, NSError *e) {
                
                for (NSURL *url in files) {
                    [[NSFileManager defaultManager]removeItemAtURL:url error:nil];
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    [view dismiss];
                    self.mediaPlayer.mediaURL = url;
                    self.mediaPlayer.videoGravity = AVLayerVideoGravityResizeAspect;
                    self.mediaPlayer.delegate = self;
                    self.mediaPlayer.playWhileDownload = YES;
                    
                    self.mediaPlayer.autoplay = YES;
                    [self.mediaPlayer startLoad];
                });
            }];
        });
        
        //        dispatch_async(dispatch_get_main_queue(), ^{
        //            AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:self.composition];
        //            playerItem.videoComposition = nil;
        //            [self.mediaPlayer startLoadWithPlayerItem:playerItem];
        //
        
        //        });
    }];
}

@end
