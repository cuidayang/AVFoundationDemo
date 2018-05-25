//
//  CombinedMediaViewController.m
//  AVFoundationDemo
//
//  Created by leoking870 on 2018/5/10.
//  Copyright © 2018年 leoking870. All rights reserved.
//

#import "CombinedMediaViewController.h"
#import "KYCombinedMediaView.h"
@interface CombinedMediaViewController ()<KYCombinedMediaViewDelegate>
@property (weak, nonatomic) IBOutlet UILabel *currentTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *videoLoadingTime;
@property (weak, nonatomic) IBOutlet UILabel *audioLoadingTime;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (nonatomic, strong) NSTimer *timer;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *indicatorView;
@property (weak, nonatomic) IBOutlet KYCombinedMediaView *mediaPlayerView;
@end

@implementation CombinedMediaViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    __weak typeof(self) wself = self;
    self.mediaPlayerView.videoURL = [NSURL URLWithString:@"http://file.kuyinyun.com//group3/M00/3C/E1/rBBGrFrdeC6AFNDsABwZkXvPK8U185.mp4"];
    //http://file.kuyinyun.com//group3/M00/15/72/rBBGrFgtZzmAOsJCAB2KNT8-y2M526.mp4
    //http://file.kuyinyun.com//group3/M00/3C/E1/rBBGrFrdeC6AFNDsABwZkXvPK8U185.mp4
    //http://oss.kuyinyun.com/11W2MYCO/rescloud2/5c3bd67e32f562ab16c1b8be7d64ea79.mp4
    self.mediaPlayerView.audioURL = [NSURL URLWithString:@"http://file.kuyinyun.com/group3/M00/59/18/rBBGq1hbRbCAE6sbABEuV8WMfWA328.aac"];
    self.mediaPlayerView.autoplay = YES;
    self.mediaPlayerView.playWhileDownload = YES;
    self.mediaPlayerView.delegate = self;
    self.mediaPlayerView.systemResourceLoader = NO;
    self.mediaPlayerView.loopMode = KYCombinedMediaViewLoopModeSeparate;
    self.mediaPlayerView.preferredBufferDurationBeforePlayback = 5;
    [self.mediaPlayerView startLoad];
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        wself.timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:wself selector:@selector(addTime) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] run];
    });
    
    
    
    [self.indicatorView startAnimating];
}

- (void)addTime {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.currentTimeLabel.text = [NSString stringWithFormat:@"%.0f", self.mediaPlayerView.currentTime];
        self.videoLoadingTime.text = [NSString stringWithFormat:@"%.0f", self.mediaPlayerView.videoLoadedTime];
        self.audioLoadingTime.text =[NSString stringWithFormat:@"%.0f", self.mediaPlayerView.audioLoaedTime];
        

    });
}

- (BOOL)combinedMediaViewShouldAutoPlayStart:(KYCombinedMediaView *)mediaPlayerView {
    [self.indicatorView stopAnimating];
    return YES;
}

- (BOOL)combinedMediaViewShouldPlaybackFromBuffering:(KYCombinedMediaView *)mediaPlayerView {
    [self.indicatorView stopAnimating];
    return YES;
}

- (void)combinedMediaViewPauseForBuffering:(KYCombinedMediaView *)mediaPlayerView {
    [self.indicatorView startAnimating];
}




- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self.timer invalidate];
    self.timer = nil;
}


@end
