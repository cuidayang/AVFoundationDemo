//
//  NSArray+TFCore.h
//  TFFoundation
//
//  Created by TFAppleWork-Summer on 2017/3/8.
//  Copyright © 2017年 TFAppleWork-Summer. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 map返回新的元素的block

 @param obj 原数组中的元素
 @param idx 原数组中的元素所在的索引
 @return 新的元素
 */
typedef __nullable id(^TFArrayMapBlock)(__nonnull id obj, NSInteger idx);

/**
 predicate，返回是否符合条件的block

 @param obj 原数组中的元素
 @param idx 原数组中的元素所在的索引
 @return 是否符合条件
 */
typedef BOOL(^TFArrayPredicateBlock)(__nonnull id obj, NSInteger idx);

/**
 数组的快捷方法类别
 */
@interface NSArray (TFCore)

///=============================================================================
/// @name 数据越界预处理读取和快捷读取转换
///=============================================================================

/**
 根据索引返回数据，并处理越界，当越界时返回nil

 @param index 索引
 @return object or nil.
 */
- (nullable id)tf_objectAtIndex:(NSInteger)index;

/**
 根据索引返回字符串并做自动转换，该方法会NSNumber自动转换成字符串

 @param index 索引
 @return NSString
 */
- (nullable NSString *)tf_stringAtIndex:(NSInteger)index;

/**
 根据索引返回NSNumber并做自动转换，该方法会将NSString自动转换成NSNumber

 @param index 索引
 @param numberStyle 数字格式
 @return NSNumber
 */
- (nullable NSNumber *)tf_numberAtIndex:(NSInteger)index numberStyle:(NSNumberFormatterStyle)numberStyle;

/**
 根据索引并做自动转换返回NSInteger

 @param index 索引
 @return NSInteger
 */
- (NSInteger)tf_integerWithIndex:(NSInteger)index;

/**
 根据索引并做自动转换返回BOOL，

 @param index 索引
 @return BOOL
 */
- (BOOL)tf_boolWithIndex:(NSInteger)index;

/**
 根据索引并做自动转换返回float

 @param index 索引
 @return float
 */
- (float)tf_floatWithIndex:(NSInteger)index;

/**
 根据索引并做自动转换返回double

 @param index 索引
 @return double
 */
- (double)tf_doubleWithIndex:(NSInteger)index;

///=============================================================================
/// @name 快速处理数据方法--包含筛选、匹配、排序等等。
///=============================================================================

- (nonnull NSArray *)tf_arrayByReverse;


/**
 根据数组中的数据，重新构建一个新的数据的数组

 @param block 返回新的元素的block
 @return NSArray
 */
- (nonnull NSArray *)tf_mapUsingBlock:(nonnull TFArrayMapBlock)block;

/**
 根据数组中的数据和遍历方式，重新构建一个新的数据的数组

 @param options 遍历方式
 @param block 返回新的元素的block
 @return NSArray
 */
- (nonnull NSArray *)tf_mapWithOptions:(NSEnumerationOptions)options usingBlock:(nonnull TFArrayMapBlock)block;

/**
 根据筛选条件获取数组中对应的某个元素，当方法匹配到数据时，便会停止遍历。

 @param predicateBlock 筛选条件的block
 @return id 匹配的数据若不存在则返回nil
 */
- (nullable id)tf_matchObjectWithPredicateBlock:(nonnull TFArrayPredicateBlock)predicateBlock;

/**
 根据筛选条件以及遍历方式获取数组中对应的某个元素，当方法匹配到数据时，便会停止遍历。

 @param options 遍历方式
 @param predicateBlock 筛选条件的block
 @return id 匹配的数据若不存在则返回nil
 */
- (nullable id)tf_matchObjectWithOptions:(NSEnumerationOptions)options predicateBlock:(nonnull TFArrayPredicateBlock)predicateBlock;

/**
 根据筛选条件获取符合条件的新数组

 @param predicateBlock > 筛选条件的block
 >
 根据返回的BOOL值返回是否筛选的为该元素，参数如下：
 > >
 obj 数组中的元素
 @return NSArray
 */
- (nullable NSArray *)tf_filteredWithPredicateBlock:(nonnull TFArrayPredicateBlock)predicateBlock;

/**
 根据谓词筛选并获取符合条件的新数组
 
 @param predicateFormat 谓词格式化字符串
 @param ... 格式化字符串
 @return NSArray
 */
- (nullable NSArray *)tf_filteredWithPredicateFormat:(nonnull NSString *)predicateFormat, ...;

/**
 根据是否升序排列数组

 @param ascending 是否升序
 @warning 此方法只试用与数组中的元素类型都为NSString或者NSNumber时，快速升序或者排序排列后的数组
 @return NSArray 排序后的数组
 */
- (nonnull NSArray *)tf_sortedArrayWithAscending:(BOOL)ascending;

/**
 根据描述字典排序数组

 @param descriptorDic > 筛选字典格式如下:
 >> 
 key:筛选的字符串，可以为字典的key或者数据模型的属性，以及属性的属性.
 >> 
 value:是否升序
 >> 
 示例：@{@"propertyNameOrKeyName":@NO}
 
 @return NSArray
 */
- (nonnull NSArray *)tf_sortedArrayWithDescriptorDic:(nonnull NSDictionary<NSString *,NSNumber *> *)descriptorDic;


- (nonnull NSArray*)tf_arrayByRemovingObject:(nonnull id)object;

- (nonnull NSArray*)tf_arrayByRemovingObjectAtIndex:(NSUInteger)index;

+ (void)performOperation:(void(^_Nullable)(_Nonnull id obj1,_Nonnull id obj2))operation onArray1:(NSArray* _Nonnull )array1 array2:( NSArray* _Nonnull)array2;

@end

