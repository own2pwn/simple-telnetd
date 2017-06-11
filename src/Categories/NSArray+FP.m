//
//  NSArray+FP.m
//
//  Created by Dmitry Rodionov
//  Copyright © 2017 Internals Exposed. All rights reserved.
//

#import "NSArray+FP.h"

@implementation NSArray (Functional)

- (nonnull id)rd_reduce: (nonnull id _Nonnull (^)(id _Nonnull sum, id _Nonnull el))mapper from: (nonnull id)memo
{
    __block id mutableMemo = memo;
    [self enumerateObjectsUsingBlock: ^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        mutableMemo = mapper(mutableMemo, obj);
    }];
    return mutableMemo;
}

- (nonnull NSArray *)rd_map: (nonnull id (^)(id obj))mapper
{
    NSMutableArray *result = [NSMutableArray arrayWithCapacity: self.count];
    [self enumerateObjectsUsingBlock: ^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [result addObject: mapper(obj)];
    }];
    return result;
}

- (nonnull NSArray *)rd_flatMap: (nonnull id _Nullable (^)(id _Nonnull obj))mapper
{
    NSMutableArray *result = [NSMutableArray array];
    [self enumerateObjectsUsingBlock: ^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        id x = mapper(obj);
        if ([x isKindOfClass:[NSArray class]]) {
            [result addObjectsFromArray: x];
        } else if (x != nil) {
            [result addObject:x];
        }
    }];
    return result;
}

- (NSArray *)rd_filter:(BOOL (^)(id))block
{
    NSMutableArray *new = [NSMutableArray array];
    [self enumerateObjectsUsingBlock: ^(id obj, NSUInteger idx, BOOL *stop) {
        if (block(obj)) [new addObject: obj];
    }];
    return new;
}

- (void)rd_each: (nonnull void (^)(id _Nonnull obj))block
{
    [self enumerateObjectsUsingBlock: ^(id _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        block(obj);
    }];
}

- (nonnull NSArray *)rd_distinct
{
    return [[NSOrderedSet orderedSetWithArray: self] array];
}

- (nullable id)rd_randomItem
{
    return self.count == 0 ? nil : self[arc4random_uniform((uint32_t)self.count)];
}

@end
