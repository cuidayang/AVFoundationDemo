//
//  TFDefine.h
//  TFFoundation
//
//  Created by TFAppleWork-Summer on 2017/3/21.
//  Copyright © 2017年 TFAppleWork-Summer. All rights reserved.
//

#import <UIKit/UIKit.h>

#ifdef DEBUG
#define TFLog(format, ...) NSLog((@"\n%s [Line %d] *********************************\n" format @"\n*********************************"), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
#else
#define TFLog(format, ...)
#endif

#define TF_SWAP(_a_, _b_)  do { __typeof__(_a_) _tmp_ = (_a_); (_a_) = (_b_); (_b_) = _tmp_; } while (0)

#ifndef weakify
#if DEBUG
#if __has_feature(objc_arc)
#define weakify(object) @autoreleasepool{} __weak __typeof__(object) weak##_##object = object;
#else
#define weakify(object) @autoreleasepool{} __block __typeof__(object) block##_##object = object;
#endif
#else
#if __has_feature(objc_arc)
#define weakify(object) @try{} @finally{} {} __weak __typeof__(object) weak##_##object = object;
#else
#define weakify(object) @try{} @finally{} {} __block __typeof__(object) block##_##object = object;
#endif
#endif
#endif

#ifndef strongify
#if DEBUG
#if __has_feature(objc_arc)
#define strongify(object) @autoreleasepool{} __typeof__(object) object = weak##_##object;
#else
#define strongify(object) @autoreleasepool{} __typeof__(object) object = block##_##object;
#endif
#else
#if __has_feature(objc_arc)
#define strongify(object) try{} @finally{} __typeof__(object) object = weak##_##object;
#else
#define strongify(object) try{} @finally{} __typeof__(object) object = block##_##object;
#endif
#endif
#endif

/**
 TFRun block.
 */
typedef void (^TFRun)(void);

/**
 *  后台执行
 *
 *  @param run run block.
 */
void TFAsyncRun(TFRun __nullable run);

/**
 *  主线程执行
 *
 *  @param run run block.
 */
void TFMainRun(TFRun __nullable run);

CGSize TFScreenSize();

#define kScreenWidth TFScreenSize().width

#define kScreenHeight TFScreenSize().height

#define kScreenScale [UIScreen mainScreen].scale;


/**
 方法置换
 
 @param cls 置换的类
 @param originalSelector 原来的方法
 @param swizzledSelector 置换后的方法
 */
extern void TFSwizzleMethod(Class __nonnull cls, SEL __nonnull originalSelector, SEL __nonnull swizzledSelector);

