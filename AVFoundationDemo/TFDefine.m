//
//  TFDefine.m
//  TFFoundation
//
//  Created by TFAppleWork-Summer on 2017/3/21.
//  Copyright © 2017年 TFAppleWork-Summer. All rights reserved.
//

#import "TFDefine.h"
#import <objc/runtime.h>

void TFAsyncRun(TFRun run) {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        run();
    });
}

void TFMainRun(TFRun run) {
    dispatch_async(dispatch_get_main_queue(), ^{
        run();
    });
}


CGSize TFScreenSize() {
    CGSize size = [UIScreen mainScreen].bounds.size;
    if (size.height < size.width) {
        CGFloat tmp = size.height;
        size.height = size.width;
        size.width = tmp;
    }
    return size;
}

void TFSwizzleMethod(Class cls, SEL originalSelector, SEL swizzledSelector) {
    Method originalMethod = class_getInstanceMethod(cls, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(cls, swizzledSelector);
    
    BOOL didAddMethod =
    class_addMethod(cls,
                    originalSelector,
                    method_getImplementation(swizzledMethod),
                    method_getTypeEncoding(swizzledMethod));
    
    if (didAddMethod) {
        class_replaceMethod(cls,
                            swizzledSelector,
                            method_getImplementation(originalMethod),
                            method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}
