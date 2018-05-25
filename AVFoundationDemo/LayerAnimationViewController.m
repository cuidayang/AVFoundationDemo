//
//  LayerAnimationViewController.m
//  AVFoundationDemo
//
//  Created by leoking870 on 2018/5/14.
//  Copyright © 2018年 leoking870. All rights reserved.
//

#import "LayerAnimationViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>
#import "AVFoundationUtils.h"
#import "CAAnimationUtils.h"
@interface LayerAnimationViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@property (weak, nonatomic) IBOutlet UITextField *fromTX;
@property (weak, nonatomic) IBOutlet UITextField *fromTY;
@property (weak, nonatomic) IBOutlet UITextField *fromTZ;
@property (weak, nonatomic) IBOutlet UITextField *toTX;
@property (weak, nonatomic) IBOutlet UITextField *toTY;
@property (weak, nonatomic) IBOutlet UITextField *toTZ;
@end

@implementation LayerAnimationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    //self.glimpse = [[Glimpse alloc]init];
    [self.imageView.layer setContents:(id)[[UIImage imageNamed:@"2"] CGImage]];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
}

- (void)merge {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            NSMutableArray *files = [NSMutableArray arrayWithCapacity:5];
            for (int i = 1; i < 2; ++i) {
                [files addObject:[UIImage imageNamed:[NSString stringWithFormat:@"%d", i]]];
            }
            NSArray *images = [[files arrayByAddingObjectsFromArray:files]arrayByAddingObjectsFromArray:files];
            NSURL *url2 = [AVFoundationUtils generateVideoFromImage:nil targetSize:CGSizeMake(720, 1280) duration:images.count * 2];
            [AVFoundationUtils addImages:images displayDuration:1 animationDuration:1 toVideo:url2 blurBackground:YES completion:^(NSURL *url, NSError *error) {
                [[NSFileManager defaultManager]removeItemAtURL:url2 error:nil];
                NSLog(@"url:%@", url);
            }];
        });

}

- (IBAction)btn1:(id)sender {
    [self merge];
//    UIImage *animationImage = [UIImage imageNamed:@"2"];
    //[self.imageView.layer setContents:(id)[[UIImage imageNamed:@"2"] CGImage]];
    
//    CAKeyframeAnimation *fadeInAndOutAnimation = [CAKeyframeAnimation animationWithKeyPath:@"contents"];
//    fadeInAndOutAnimation.beginTime = 0;
//    [fadeInAndOutAnimation setCalculationMode:kCAAnimationDiscrete];
//    fadeInAndOutAnimation.duration = 10;
//    fadeInAndOutAnimation.keyTimes = @[@2, @4, @6, @8];
//    fadeInAndOutAnimation.values = @[(id)[[UIImage imageNamed:@"2"] CGImage], (id)[[UIImage imageNamed:@"3"] CGImage], (id)[[UIImage imageNamed:@"4"] CGImage], (id)[[UIImage imageNamed:@"5"] CGImage]];
//    fadeInAndOutAnimation.removedOnCompletion = NO;
//    fadeInAndOutAnimation.fillMode = kCAFillModeForwards;
//    [self.imageView.layer addAnimation:fadeInAndOutAnimation forKey:@"contents"];
//
    
//    CATransition *transition = [CATransition animation];
//    transition.duration = 3;
//    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
//    transition.type = @"cube";//`fade', `moveIn', `push' and `reveal'
//    transition.subtype = kCATransitionFromTop;
////    transition.beginTime = 2;
////    transition.timeOffset = 3;
//    transition.removedOnCompletion = NO;
//    [self.imageView.layer addAnimation:transition forKey:@"transition"];
//
//    animationImage = [UIImage imageNamed:@"3"];
//    [self.imageView.layer setContents:(id)[animationImage CGImage]];
    
    
//    CAAnimation *transition = [CAAnimationUtils cubeRotateFromAngle:0 toAngle:-M_PI_2 size:self.view.frame.size];
    CAAnimation *transition = [CAAnimationUtils flipAlongAxis:CAAnimationRotateAxisY fromAngle:0 toAngle:M_PI_2 value:self.view.frame.size.width/2];
    transition.duration = 3;
//    transition.beginTime = CACurrentMediaTime();
    transition.removedOnCompletion = NO;
    [self.imageView.layer addAnimation:transition forKey:nil];
    
    CAAnimation *transition2 = [CAAnimationUtils flipAlongAxis:CAAnimationRotateAxisY fromAngle:-M_PI_2 toAngle:0 value:self.view.frame.size.width/2];
    transition2.duration = 3;
    transition2.beginTime = CACurrentMediaTime()+3;
    transition2.removedOnCompletion = NO;
    [self.imageView.layer addAnimation:transition2 forKey:nil];
}

- (IBAction)btn2:(id)sender {
    //[self.glimpse stop];
    
    CATransform3D fromTrans = CATransform3DMakeTranslation(self.fromTX.text.intValue, self.fromTY.text.intValue, self.fromTY.text.intValue);
    CATransform3D toTrans = CATransform3DMakeTranslation(self.toTX.text.intValue, self.toTY.text.intValue, self.toTZ.text.intValue);
    
    CAAnimation *transition = [CAAnimationUtils cubeRotateFromAngle:-M_PI_2 fromTrans:fromTrans toAngle:0 toTrans:toTrans size:self.view.frame.size];
    transition.duration = 3;
    
    transition.removedOnCompletion = NO;
    [self.imageView.layer addAnimation:transition forKey:@"transition"];
}

@end
