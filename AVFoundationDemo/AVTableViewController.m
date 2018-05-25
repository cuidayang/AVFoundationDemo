//
//  AVTableViewController.m
//  AVFoundationDemo
//
//  Created by leoking870 on 2018/5/10.
//  Copyright © 2018年 leoking870. All rights reserved.
//

#import "AVTableViewController.h"
#import "ViewController.h"
@interface AVTableViewController ()

@end

@implementation AVTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
}




#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if ([segue.identifier isEqualToString:@"customLoader"]) {
        ViewController *vc = segue.destinationViewController;
        vc.systemResourceLoader = NO;
    }
    else if ([segue.identifier isEqualToString:@"systemLoader"]){
        ViewController *vc = segue.destinationViewController;
        vc.systemResourceLoader = YES;
    }
}


@end
