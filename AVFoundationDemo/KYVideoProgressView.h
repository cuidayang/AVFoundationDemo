//
//  KYVideoProgressView.h
//  KYVideoModule
//
//  Created by leoking870 on 2018/5/23.
//

#import <UIKit/UIKit.h>

@interface KYVideoProgressView : UIView
@property (nonatomic, strong) NSString *message;
@property (nonatomic, assign) CGFloat progress;

+ (KYVideoProgressView *)showProgressViewWithMessage:(NSString *)message;

- (void)dismiss;

@end
