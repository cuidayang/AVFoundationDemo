//
//  UIView+DimView.h
//  KYVideoModule
//
//  Created by leoking870 on 2017/9/27.
//

#import <UIKit/UIKit.h>

@interface UIView (DimView)


/**
 给view下面加一个蒙版view, 颜色为黑色,alpha=0, 点击蒙版view执行block
 
 @return 蒙版view
 */
- (UIView *)addDimBackgroundViewForView:(UIView *)view tapToExecute:(void(^)(void))block;

/**
 设置蒙版view的透明度

 @param alpha 透明度
 */
- (void)setDimViewAlpha:(CGFloat)alpha forView:(UIView*)view;

/**
 移出蒙版view
 */
- (void)removeDimViewForView:(UIView *)view;

/**
 * 以view为参数生成一个tag,
 * @param view
 * @return
 */
+ (NSInteger)viewTagWithParameterView:(UIView *)view;
@end
