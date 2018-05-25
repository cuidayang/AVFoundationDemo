//
//  AVUtils.h
//  KYVideoModule
//
//  Created by leoking870 on 2017/10/30.
//

#import <Foundation/Foundation.h>

@interface AVUtils : NSObject

/**
 合并视频(可以包含音轨)
 @param filepaths 视频地址列表
 @param musicPath 音乐地址
 @param destinationPath 合并完的目标地址
 @param saveToLibrary 是否将合并后的视频保存到相册
 @param completion handler
 */
+ (void)mergeVideoFiles:(NSArray<NSString *> *)filepaths
               musicURL:(NSURL *)musicURL
                 atPath:(NSString *)destinationPath
          saveToLibrary:(BOOL)saveToLibrary
             completion:(void (^)(BOOL mergeSuccess, BOOL saveSuccess))completion;

@end
