//
//  CAAnimationUtils.h
//  AVFoundationDemo
//
//  Created by leoking870 on 2018/5/18.
//  Copyright © 2018年 leoking870. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, CAAnimationRotateAxis) {
    CAAnimationRotateAxisX,
    CAAnimationRotateAxisY,
};


@interface CAAnimationUtils : NSObject
+ (CAAnimation *)moveWithPositions:(NSArray *)values;
+ (CAAnimation *)animateContentWithImages:(NSArray *)images;
+ (CAAnimation *)moveFrom:(CGPoint)from to:(CGPoint)to;
+ (CAAnimation *)moveto:(CGPoint)to;

+ (CAAnimation *)opacityFrom:(CGFloat)from to:(CGFloat)to;

+ (CAAnimation *)scaleFrom:(CGFloat)from to:(CGFloat)to;

+ (CAAnimation *)rotateFrom:(CGFloat)from to:(CGFloat)to;

+ (CAAnimation *)cubeRotateFromAngle:(CGFloat)fromAngle fromTrans:(CATransform3D)fromTrans toAngle:(CGFloat)toAngle toTrans:(CATransform3D)toTrans size:(CGSize)size;

+ (CAAnimation *)cubeRotateAlongAxis:(CAAnimationRotateAxis)axis fromAngle:(CGFloat)fromAngle toAngle:(CGFloat)toAngle value:(CGFloat)value;

+ (CAAnimation *)flipAlongAxis:(CAAnimationRotateAxis)axis fromAngle:(CGFloat)fromAngle toAngle:(CGFloat)toAngle value:(CGFloat)value;

@end
