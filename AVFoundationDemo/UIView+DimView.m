//
//  UIView+DimView.m
//  KYVideoModule
//
//  Created by leoking870 on 2017/9/27.
//

#import "UIView+DimView.h"
#import "Masonry.h"
#import "UIGestureRecognizer+YYAdd.h"

@implementation UIView (DimView)

static inline NSUInteger hexStrToInt(NSString *str) {
    uint32_t result = 0;
    sscanf([str UTF8String], "%X", &result);
    return result;
}

+ (NSInteger)viewTagWithParameterView:(UIView *)view {
    NSString *hexStr = [NSString stringWithFormat:@"%x", view];
    hexStr = [hexStr substringWithRange:NSMakeRange(hexStr.length / 2, hexStr.length / 2)];
    return hexStrToInt(hexStr);
}

- (UIView *)addDimBackgroundViewForView:(UIView *)view tapToExecute:(void (^)(void))block {
    UIView *grayBackgroundView = [[UIView alloc] initWithFrame:self.bounds];
    grayBackgroundView.backgroundColor = [UIColor colorWithWhite:0 alpha:0];
    grayBackgroundView.tag = [UIView viewTagWithParameterView:view];
    [self addSubview:grayBackgroundView];
    [grayBackgroundView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self);
    }];
    if (block) {
        grayBackgroundView.userInteractionEnabled = YES;
        UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithActionBlock:^(id sender) {
            block();
        }];
        [grayBackgroundView addGestureRecognizer:tapGestureRecognizer];
    }
    else {
        grayBackgroundView.userInteractionEnabled = NO;
    }
    return grayBackgroundView;
}

- (void)setDimViewAlpha:(CGFloat)alpha forView:(UIView *)view {
    UIView *grayBackgroundView = [self viewWithTag:[UIView viewTagWithParameterView:view]];
    grayBackgroundView.backgroundColor = [UIColor colorWithWhite:0 alpha:alpha];
}

- (void)removeDimViewForView:(UIView *)view {
    UIView *grayBackgroundView = [self viewWithTag:[UIView viewTagWithParameterView:view]];
    [grayBackgroundView removeFromSuperview];
}

@end
