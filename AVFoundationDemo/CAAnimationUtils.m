//
//  CAAnimationUtils.m
//  AVFoundationDemo
//
//  Created by leoking870 on 2018/5/18.
//  Copyright © 2018年 leoking870. All rights reserved.
//

#import "CAAnimationUtils.h"
CATransform3D CATransform3DMakePerspective(CGPoint center, float disZ)
{
    CATransform3D transToCenter = CATransform3DMakeTranslation(-center.x, -center.y, 0);
    CATransform3D transBack = CATransform3DMakeTranslation(center.x, center.y, 0);
    CATransform3D scale = CATransform3DIdentity;
    scale.m34 = -1.0f/disZ;
    return CATransform3DConcat(CATransform3DConcat(transToCenter, scale), transBack);
}
CATransform3D CATransform3DPerspect(CATransform3D t, CGPoint center, float disZ)
{
    return CATransform3DConcat(t, CATransform3DMakePerspective(center, disZ));
}
@implementation CAAnimationUtils
+ (CAAnimation *)moveWithPositions:(NSArray *)values {
    CAKeyframeAnimation *animation1 = [CAKeyframeAnimation animationWithKeyPath:@"position"];
    animation1.values = values;
    animation1.calculationMode = kCAAnimationLinear;
    animation1.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    animation1.fillMode = kCAFillModeForwards;
    animation1.removedOnCompletion = NO;
    return animation1;
}

+ (CAAnimation *)animateContentWithImages:(NSArray *)images {
    CAKeyframeAnimation *animation1 = [CAKeyframeAnimation animationWithKeyPath:@"contents"];
    animation1.values = images;
    animation1.calculationMode = kCAAnimationLinear;
    animation1.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    animation1.fillMode = kCAFillModeForwards;
    animation1.removedOnCompletion = NO;
    return animation1;
}

+ (CAAnimation *)moveFrom:(CGPoint)from to:(CGPoint)to {
    CABasicAnimation *moveOut = [CABasicAnimation animationWithKeyPath:@"position"];
    moveOut.fromValue = [NSValue valueWithCGPoint:from];
    moveOut.toValue = [NSValue valueWithCGPoint:to];
    moveOut.removedOnCompletion = NO;
    moveOut.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    moveOut.fillMode = kCAFillModeForwards;
    return moveOut;
}

+ (CAAnimation *)opacityFrom:(CGFloat)from to:(CGFloat)to {
    CABasicAnimation *moveOut = [CABasicAnimation animationWithKeyPath:@"opacity"];
    moveOut.fromValue = @(from);
    moveOut.toValue = @(to);
    moveOut.removedOnCompletion = NO;
    moveOut.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    moveOut.fillMode = kCAFillModeForwards;
    return moveOut;
}

+ (CAAnimation *)scaleFrom:(CGFloat)from to:(CGFloat)to {
    CABasicAnimation *moveOut = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    moveOut.fromValue = @(from);
    moveOut.toValue = @(to);
    moveOut.removedOnCompletion = NO;
    moveOut.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    moveOut.fillMode = kCAFillModeForwards;
    moveOut.cumulative = YES;
    return moveOut;
}

+ (CAAnimation *)rotateFrom:(CGFloat)from to:(CGFloat)to {
    CABasicAnimation *moveOut = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    moveOut.fromValue = @(from);
    moveOut.toValue = @(to);
    moveOut.removedOnCompletion = NO;
    moveOut.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    moveOut.fillMode = kCAFillModeForwards;
    moveOut.cumulative = YES;
    return moveOut;
}

+ (CAAnimation *)moveto:(CGPoint)to {
    CABasicAnimation *moveOut = [CABasicAnimation animationWithKeyPath:@"position"];
    moveOut.toValue = [NSValue valueWithCGPoint:to];
    moveOut.removedOnCompletion = NO;
    moveOut.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    moveOut.fillMode = kCAFillModeForwards;
    return moveOut;
}

+ (CATransform3D)flipTransformAlgonAxis:(CAAnimationRotateAxis)axis angle:(CGFloat)angle value:(CGFloat)value depth:(CGFloat)depth{
    CATransform3D transloate = CATransform3DMakeTranslation(0, 0, -value);
    CATransform3D rotate = axis == CAAnimationRotateAxisX ? CATransform3DMakeRotation(angle, 1, 0, 0):CATransform3DMakeRotation(angle, 0, 1, 0);
    CATransform3D mat = CATransform3DConcat(rotate, transloate);
    
    return CATransform3DPerspect(mat, CGPointMake(0, 0), depth);
}

+ (CATransform3D)transformAlongAxis:(CAAnimationRotateAxis)axis angle:(CGFloat)angle value:(CGFloat)value{
    CATransform3D move = CATransform3DMakeTranslation(0, 0, value);
    CATransform3D back = CATransform3DMakeTranslation(0, 0, -value);
    CATransform3D rotate0 = axis == CAAnimationRotateAxisX ? CATransform3DMakeRotation(angle, 1, 0, 0) : CATransform3DMakeRotation(angle, 0, 1, 0);
    CATransform3D mat0 = CATransform3DConcat(CATransform3DConcat(move, rotate0), back);
    return CATransform3DPerspect(mat0, CGPointZero, 500);
}

+ (CAAnimation *)flipAlongAxis:(CAAnimationRotateAxis)axis fromAngle:(CGFloat)fromAngle toAngle:(CGFloat)toAngle value:(CGFloat)value {
    CAKeyframeAnimation *animation1 = [CAKeyframeAnimation animationWithKeyPath:@"transform"];
    int count = 5;
    NSMutableArray *values = [NSMutableArray arrayWithCapacity:count];
    for (int i = 0; i <= count; ++i) {
        [values addObject:[NSValue valueWithCATransform3D:[self flipTransformAlgonAxis:axis angle:(fromAngle + (toAngle - fromAngle)*i/count) value:value depth:CGFLOAT_MAX]]];
    }
    animation1.values = [values copy];
    animation1.calculationMode = kCAAnimationLinear;
    animation1.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    animation1.fillMode = kCAFillModeForwards;
    animation1.removedOnCompletion = NO;
    
    return animation1;
}

+ (CAAnimation *)cubeRotateAlongAxis:(CAAnimationRotateAxis)axis fromAngle:(CGFloat)fromAngle toAngle:(CGFloat)toAngle value:(CGFloat)value {
    CAKeyframeAnimation *animation1 = [CAKeyframeAnimation animationWithKeyPath:@"transform"];
    int count = 5;
    NSMutableArray *values = [NSMutableArray arrayWithCapacity:count];
    for (int i = 0; i <= count; ++i) {
        [values addObject:[NSValue valueWithCATransform3D:[self transformAlongAxis:axis angle:(fromAngle + (toAngle - fromAngle)*i/count) value:value]]];
    }
    animation1.values = [values copy];
    animation1.calculationMode = kCAAnimationLinear;
    animation1.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    animation1.fillMode = kCAFillModeForwards;
    animation1.removedOnCompletion = NO;
    
    return animation1;
}

+ (CAAnimation *)cubeRotateFromAngle:(CGFloat)fromAngle
                           fromTrans:(CATransform3D)fromTrans
                             toAngle:(CGFloat)toAngle
                             toTrans:(CATransform3D)toTrans
                                size:(CGSize)size{
    
//    CATransform3D move = CATransform3DMakeTranslation(0, 0, 0);
//    CATransform3D back = CATransform3DMakeTranslation(0, 0, size.width);
    
    CATransform3D rotate0 = CATransform3DMakeRotation(fromAngle, 0, 1, 0);
    CATransform3D from = CATransform3DConcat(fromTrans, rotate0);
    
    //向屏幕前方移动
    CATransform3D move = CATransform3DMakeTranslation(0, 0, size.width/2);
    //旋转
    CATransform3D rotate = CATransform3DMakeRotation(toAngle, 0, 1, 0);
    //平移
    CATransform3D plaintMove = CATransform3DMakeTranslation( -size.width, 0, 0);
    //向屏幕后方移动
    CATransform3D back = CATransform3DMakeTranslation(0, 0, -size.width/2);
    //连接
    CATransform3D concat = CATransform3DConcat(CATransform3DConcat(move, CATransform3DConcat(rotate, plaintMove)),back);
    CATransform3D transform = CATransform3DPerspect(concat, CGPointZero, 5000.0f);
    
    CABasicAnimation *moveOut = [CABasicAnimation animationWithKeyPath:@"transform"];
    moveOut.fromValue = [NSValue valueWithCATransform3D:CATransform3DPerspect(from, CGPointZero, 200)];
    moveOut.toValue = [NSValue valueWithCATransform3D:transform];
    moveOut.removedOnCompletion = NO;
    moveOut.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    moveOut.fillMode = kCAFillModeForwards;
    return moveOut;
}

@end
