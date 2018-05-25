//
//  KYProgressView.h
//  KYVideoModule
//
//  Created by leoking870 on 2018/3/2.
//

#import <UIKit/UIKit.h>


IB_DESIGNABLE
@interface KYProgressView : UIView
@property(nonatomic, assign) IBInspectable CGFloat progress;
/**
 * 进度条轨道颜色
 */
@property(nonatomic, strong) IBInspectable UIColor *trackColor;
/**
 * 进度条颜色
 */
@property(nonatomic, strong) IBInspectable UIColor *progressColor;
/**
 * 进度条轨道宽度, 默认为2
 */
@property(nonatomic, assign) IBInspectable CGFloat trackWidth;
/**
 * 进度条宽度, 默认为4
 */
@property(nonatomic, assign) IBInspectable CGFloat progressWidth;
@property(nonatomic, strong) IBInspectable UIColor *progressTextColor;
@property(nonatomic, strong) IBInspectable UIFont *progressTextFont;
@end
