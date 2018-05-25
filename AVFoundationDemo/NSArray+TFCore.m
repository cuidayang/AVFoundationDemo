//
//  NSArray+TFCore.m
//  TFFoundation
//
//  Created by TFAppleWork-Summer on 2017/3/8.
//  Copyright © 2017年 TFAppleWork-Summer. All rights reserved.
//

#import "NSArray+TFCore.h"

@implementation NSArray (TFCore)

#pragma mark - 数据越界预处理读取和快捷读取转换

- (id)tf_objectAtIndex:(NSInteger)index {
    return (index < self.count && index >= 0) ? self[index] : nil;
}

- (NSString *)tf_stringAtIndex:(NSInteger)index {
    id value = [self tf_objectAtIndex:index];
    if (value == nil || value == [NSNull null] || [[value description] isEqualToString:@"<null>"])
    {
        return nil;
    }
    else if ([value isKindOfClass:[NSString class]]) {
        return (NSString*)value;
    }
    else if ([value isKindOfClass:[NSNumber class]]) {
        return [value stringValue];
    }
    return nil;
}

- (NSNumber *)tf_numberAtIndex:(NSInteger)index numberStyle:(NSNumberFormatterStyle)numberStyle{
    id value = [self tf_objectAtIndex:index];
    if ([value isKindOfClass:[NSNumber class]]) {
        return value;
    }
    else if ([value isKindOfClass:[NSString class]]) {
        NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
        formatter.numberStyle = numberStyle;
        return [formatter numberFromString:value];
    }
    return nil;
}

- (NSInteger)tf_integerWithIndex:(NSInteger)index {
    id value = [self tf_objectAtIndex:index];
    if (value == nil || value == [NSNull null])
    {
        return 0;
    }
    if ([value isKindOfClass:[NSString class]] || [value isKindOfClass:[NSNumber class]])
    {
        return [value integerValue];
    }
    return 0;
}

- (BOOL)tf_boolWithIndex:(NSInteger)index {
    id value = [self tf_objectAtIndex:index];
    if (value == nil || value == [NSNull null])
    {
        return NO;
    }
    if ([value isKindOfClass:[NSNumber class]])
    {
        return [value boolValue];
    }
    if ([value isKindOfClass:[NSString class]])
    {
        return [value boolValue];
    }
    return NO;
}

- (float)tf_floatWithIndex:(NSInteger)index {
    id value = [self tf_objectAtIndex:index];
    if (value == nil || value == [NSNull null])
    {
        return 0.0;
    }
    if ([value isKindOfClass:[NSNumber class]] || [value isKindOfClass:[NSString class]])
    {
        return [value floatValue];
    }
    return 0.0;
}

- (double)tf_doubleWithIndex:(NSInteger)index {
    id value = [self tf_objectAtIndex:index];
    if (value == nil || value == [NSNull null])
    {
        return 0.0;
    }
    if ([value isKindOfClass:[NSNumber class]] || [value isKindOfClass:[NSString class]])
    {
        return [value doubleValue];
    }
    return 0.0;
}

#pragma mark - 快速处理数据方法--包含筛选、匹配、排序等等。

- (NSArray *)tf_arrayByReverse {
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:self.count];
    [self enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [array addObject:obj];
    }];
    return [NSArray arrayWithArray:array];
}

- (NSArray *)tf_mapUsingBlock:(TFArrayMapBlock)block {
    NSMutableArray *mapArray = [NSMutableArray array];
    [self enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        id newObj = block(obj,idx);
        if (newObj) {
            [mapArray addObject:newObj];
        }
        else {
            [mapArray addObject:[NSNull null]];
        }
    }];
    return [NSArray arrayWithArray:mapArray];
}

- (NSArray *)tf_mapWithOptions:(NSEnumerationOptions)options usingBlock:(nonnull TFArrayMapBlock)block {
    NSMutableArray *mapArray = [NSMutableArray array];
    [self enumerateObjectsWithOptions:options usingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        id newObj = block(obj,idx);
        if (newObj) {
            [mapArray addObject:newObj];
        }
        else {
            [mapArray addObject:[NSNull null]];
        }
    }];
    return [NSArray arrayWithArray:mapArray];
}

- (id)tf_matchObjectWithPredicateBlock:(TFArrayPredicateBlock)predicateBlock {
    NSInteger index = [self indexOfObjectPassingTest:^BOOL(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        return predicateBlock(obj,idx);
    }];
    return [self tf_objectAtIndex:index];
}

- (id)tf_matchObjectWithOptions:(NSEnumerationOptions)options predicateBlock:(nonnull TFArrayPredicateBlock)predicateBlock {
    NSInteger index = [self indexOfObjectWithOptions:options passingTest:^BOOL(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        return predicateBlock(obj,idx);
    }];
   return [self tf_objectAtIndex:index];
}

- (NSArray *)tf_filteredWithPredicateBlock:(TFArrayPredicateBlock)predicateBlock {
    typeof(self) __weak weakSelf = self;
    
    return [self filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id  _Nullable evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
        return predicateBlock(evaluatedObject,[weakSelf indexOfObject:evaluatedObject]);
    }]];
}

- (NSArray *)tf_filteredWithPredicateFormat:(NSString *)predicateFormat, ... {
    va_list args;
    va_start(args, predicateFormat);
    predicateFormat = [[NSString alloc] initWithFormat:predicateFormat arguments:args];
    va_end(args);
    return [self filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:predicateFormat]];
}

- (NSArray *)tf_sortedArrayWithAscending:(BOOL)ascending {
    NSSortDescriptor *sortDesc = [NSSortDescriptor sortDescriptorWithKey:nil ascending:ascending];
    return [self sortedArrayUsingDescriptors:@[sortDesc]];
}

- (NSArray *)tf_sortedArrayWithDescriptorDic:(NSDictionary<NSString *,NSNumber *> *)descriptorDic {
    NSMutableArray *descripArray = @[].mutableCopy;
    [descriptorDic enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSNumber * _Nonnull obj, BOOL * _Nonnull stop) {
        [descripArray addObject:[NSSortDescriptor sortDescriptorWithKey:key ascending:[obj boolValue]]];
    }];
    return [self sortedArrayUsingDescriptors:descripArray];
}

- (NSString *)descriptionWithLocale:(id)locale
{
    NSMutableString *str = [NSMutableString stringWithFormat:@"%lu (\n", (unsigned long)self.count];
    for (id obj in self) {
        [str appendFormat:@"\t%@, \n", obj];
    }
    [str appendString:@")"];
    
    return str;
}

- (NSArray *)tf_arrayByRemovingObject:(id)object {
    NSMutableArray* array = [self mutableCopy];
    [array removeObject:object];
    return [array copy];
}

- (NSArray *)tf_arrayByRemovingObjectAtIndex:(NSUInteger)index {
    return [self tf_arrayByRemovingObject:[self objectAtIndex:index]];
}

+ (void)performOperation:(void (^)(id, id))operation onArray1:(NSArray *)array1 array2:(NSArray *)array2 {
    unsigned long count = MIN(array1.count, array2.count);
    for (int i = 0; i < count; ++i) {
        id obj1 = array1[i];
        id obj2 = array2[i];
        operation?operation(obj1, obj2):nil;
    }
}

@end
