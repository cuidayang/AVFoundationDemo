//
//  ViewController.m
//  AVFoundationDemo
//
//  Created by leoking870 on 2018/5/8.
//  Copyright © 2018年 leoking870. All rights reserved.
//

#import "ViewController.h"
#import "MediaPlayerView.h"
#import "KYMediaPlayerView.h"
#import "KYCombinedMediaView.h"
@interface ViewController ()<KYMediaPlayerViewDelegate>
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *indicator;
@property (weak, nonatomic) IBOutlet KYMediaPlayerView *vvv;
@property (weak, nonatomic) IBOutlet UILabel *loadingRangeLabel;
@property (weak, nonatomic) IBOutlet UILabel *keepUpLabel;
@property (weak, nonatomic) IBOutlet UILabel *bufferEmptyLabel;
@property (weak, nonatomic) IBOutlet UILabel *bufferFullLabel;
@property (weak, nonatomic) IBOutlet UILabel *currentTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (nonatomic, strong) NSTimer *timer;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.vvv.delegate = self;
    self.vvv.playWhileDownload = YES;
    self.vvv.systemResourceLoader = self.systemResourceLoader;
    self.vvv.autoplay = YES;
    self.vvv.loopPlayback = NO;
    
    __weak typeof(self) wself = self;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        wself.timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:wself selector:@selector(addTime) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] run];
    });
    
    UIBarButtonItem *item1 = [[UIBarButtonItem alloc]initWithTitle:@"3:32" style:UIBarButtonItemStylePlain target:self action:@selector(onItem1Tapped:)];
    UIBarButtonItem *item2 = [[UIBarButtonItem alloc]initWithTitle:@"WWDC" style:UIBarButtonItemStylePlain target:self action:@selector(onItem2Tapped:)];
    UIBarButtonItem *item3 = [[UIBarButtonItem alloc]initWithTitle:@"2:49" style:UIBarButtonItemStylePlain target:self action:@selector(onItem3Tapped:)];
    self.navigationItem.rightBarButtonItems = @[item1, item2,item3];
}

- (void)onItem1Tapped:(id)sender {
    [self.vvv pause];
    //self.vvv.mediaURL = [NSURL URLWithString:@"http://file.kuyinyun.com//group3/M00/3C/E1/rBBGrFrdeC6AFNDsABwZkXvPK8U185.mp4"];
    self.vvv.mediaURL = [NSURL URLWithString:@"https://lanhustatic.oss-cn-beijing.aliyuncs.com/video/%E5%AE%98%E7%BD%91%E5%9B%A2%E9%98%9F%E8%A7%86%E9%A2%91.mp4"];
    [self.vvv startLoad];
    
    [self.indicator startAnimating];
}
- (void)onItem2Tapped:(id)sender {
    [self.vvv pause];
    self.vvv.mediaURL = [NSURL URLWithString:@"http://devstreaming.apple.com/videos/wwdc/2015/5062qehwhs/506/506_sd_editing_movies_in_av_foundation.mp4"];
    [self.vvv startLoad];
    [self.indicator startAnimating];
}

- (void)onItem3Tapped:(id)sender {
    [self.vvv pause];
    self.vvv.mediaURL = [NSURL URLWithString:@"https://vd3.bdstatic.com/mda-idr55m2fk9fae9cx/hd/mda-idr55m2fk9fae9cx.mp4"];
    [self.vvv startLoad];
    [self.indicator startAnimating];
}


- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self.timer invalidate];
    self.timer = nil;
}

- (void)addTime {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.loadingRangeLabel.text = [NSString stringWithFormat:@"%.0f", self.vvv.loadedTime];
        self.keepUpLabel.text = self.vvv.isPlaybackLikelyToKeepUp?@"YES":@"NO";
        self.bufferFullLabel.text = self.vvv.isPlaybackBufferFull?@"YES":@"NO";
        self.bufferEmptyLabel.text = self.vvv.isPlaybackBufferEmpty?@"YES":@"NO";
        self.currentTimeLabel.text = [NSString stringWithFormat:@"%.0f", self.vvv.currentTime];
        if (self.vvv.timeControlStatus ==  AVPlayerTimeControlStatusPlaying) {
            self.statusLabel.text = @"Playing";
        }
        else if(self.vvv.timeControlStatus == AVPlayerTimeControlStatusPaused){
            self.statusLabel.text = @"Paused";
        }
        else {
            self.statusLabel.text = @"Waiting";
        }
        
    });
}
- (IBAction)play:(id)sender {
    [self.vvv play];
}
- (IBAction)pause:(id)sender {
    [self.vvv pause];
}

- (IBAction)forward:(id)sender {
    [self.vvv seekToTime:self.vvv.currentTime + 30];
}
- (IBAction)backward:(id)sender {
    [self.vvv seekToTime:self.vvv.currentTime - 30];
}

- (void)mediaPlayerViewPauseForBuffering:(KYMediaPlayerView *)mediaPlayerView {
    [self.indicator startAnimating];
}

- (void)mediaPlayerViewDidLoadMediaSuccess:(KYMediaPlayerView *)mediaPlayerView {
    if (!self.vvv.autoplay) {
        [self.indicator stopAnimating];
    }
}

- (BOOL)mediaPlayerViewShouldPlaybackFromBuffering:(KYMediaPlayerView *)mediaPlayerView {
    [self.indicator stopAnimating];
    return YES;
}

- (BOOL)mediaPlayerViewShouldAutoPlayStart:(KYMediaPlayerView *)mediaPlayerView {
    [self.indicator stopAnimating];
    return YES;
}


@end
