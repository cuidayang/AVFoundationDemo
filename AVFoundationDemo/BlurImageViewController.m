//
//  BlurImageViewController.m
//  AVFoundationDemo
//
//  Created by leoking870 on 2018/5/15.
//  Copyright © 2018年 leoking870. All rights reserved.
//

#import "BlurImageViewController.h"
#import "UIImage+DSP.h"
#import "UIImage+StackBlur.h"
@interface BlurImageViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UITextField *textField;
@property (nonatomic, strong) CIContext *context;
@end

@implementation BlurImageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.context = [CIContext contextWithOptions:nil];
}
- (IBAction)applyBlur:(id)sender {
//    CIFilter *filter = [CIFilter filterWithName:@"CIGaussianBlur"];
    UIImage *image = [UIImage imageNamed:@"2"];
    //CIFilter *filter = [CIFilter filterWithName:@"CIGaussianBlur" keysAndValues:@"inputImage",[CIImage imageWithCGImage:image.CGImage],@"inputRadius",@10.0F,nil];
    
//    CIImage *output = filter.outputImage;
//    [filter setValue:[CIImage imageWithCGImage:image.CGImage] forKey:kCIInputImageKey];
//    [filter setValue:@(self.textField.text.floatValue) forKey:kCIInputRadiusKey];
//    CIImage *output = filter.outputImage;
//
//    UIImage *xxx = [UIImage imageWithCIImage:output];
    
//    CIImage *ciImage = [CIImage imageWithCGImage:image.CGImage];
    
//    CIImage *resultImage = [ciImage imageByApplyingGaussianBlurWithSigma:10];
    //CGImageRef cgImage  = [self.context createCGImage:resultImage fromRect:ciImage.extent];
    //UIImage *image2 = [UIImage imageWithCIImage:resultImage];
    
    UIImage *xxx = [image stackBlur:20];
    self.imageView.image = xxx;
}




@end
