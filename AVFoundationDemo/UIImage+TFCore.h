//
//  UIImage+TFCore.h
//  TFFoundation
//
//  Created by TFAppleWork-Summer on 2017/3/28.
//  Copyright © 2017年 TFAppleWork-Summer. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 模糊图片效果种类

 */
typedef NS_ENUM(NSUInteger, TFImageBlurType) {
    /**
     亮
     */
    TFImageBlurTypeLight,
    /**
     特别亮
     */
    TFImageBlurTypeExtraLight,
    /**
     黑
     */
    TFImageBlurTypeDark,
};

/**
 UIImage常用类别
 */
@interface UIImage (TFCore)

/**
 根据颜色返回图片

 @param color 颜色
 @return UIImage
 */
+ (nonnull UIImage *)tf_imageWithColor:(nonnull UIColor *)color;

/**
 根据颜色和大小返回图片

 @param color 颜色
 @param size 大小
 @return UIImage
 */
+ (nonnull UIImage *)tf_imageWithColor:(nonnull UIColor *)color size:(CGSize)size;

/**
 根据rect剪切图片

 @param rect 剪切的rect
 @return UIImage
 */
- (nullable UIImage *)tf_imageByCropToRect:(CGRect)rect;

/**
 获取圆角图片

 @param radius 圆角半径
 @return UIImage
 */
- (nullable UIImage *)tf_imageByRoundCornerRadius:(CGFloat)radius;

/**
 获取圆角以及带边框的图片

 @param radius 圆角半径
 @param borderWidth 边框宽度
 @param borderColor 边框颜色
 @return UIImage
 */
- (nullable UIImage *)tf_imageByRoundCornerRadius:(CGFloat)radius
                                   borderWidth:(CGFloat)borderWidth
                                   borderColor:(nullable UIColor *)borderColor;

/**
 获取圆角类型以及带边框的图片

 @param radius 圆角半径
 @param corners 圆角类型
 @param borderWidth 边框宽度
 @param borderColor 边框颜色
 @param borderLineJoin 连接方式
 @return UIImage
 */
- (nullable UIImage *)tf_imageByRoundCornerRadius:(CGFloat)radius
                                       corners:(UIRectCorner)corners
                                   borderWidth:(CGFloat)borderWidth
                                   borderColor:(nullable UIColor *)borderColor
                                borderLineJoin:(CGLineJoin)borderLineJoin;

/**
 获取修正图片方向的图片

 @return UIImage
 */
- (nonnull UIImage *)tf_fixOrientationImage;

/**
 获取对应的亮透明的图片

 @param blurType 模糊类型
 @return UIImage
 */
- (nonnull UIImage *)tf_blurImageWithType:(TFImageBlurType)blurType;

/**
 获取模糊效果的图片

 @param blurRadius 模糊半径
 @param tintColor 填充颜色
 @param tintBlendMode 填充类型
 @param saturation 饱和度
 @param maskImage 遮罩图片
 @return UIImage
 */
- (nullable UIImage *)tf_imageByBlurRadius:(CGFloat)blurRadius
                              tintColor:(nullable UIColor *)tintColor
                               tintMode:(CGBlendMode)tintBlendMode
                             saturation:(CGFloat)saturation
                              maskImage:(nullable UIImage *)maskImage;

@end
