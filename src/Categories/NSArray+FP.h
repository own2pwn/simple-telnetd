//
//  NSArray+FP.h
//
//  Created by Dmitry Rodionov
//  Copyright © 2017 Internals Exposed. All rights reserved.
//

@import Foundation;

@interface NSArray <ObjectType> (Functional)

- (nonnull id)rd_reduce: (nonnull id _Nonnull (^)(id _Nonnull sum, id _Nonnull el))mapper from: (nonnull id)memo;
- (nonnull NSArray *)rd_map: (nonnull id _Nonnull (^)(id _Nonnull obj))mapper;
- (nonnull NSArray *)rd_flatMap: (nonnull id _Nullable (^)(id _Nonnull obj))mapper;
- (nonnull NSArray *)rd_filter: (nonnull BOOL (^)(id _Nonnull obj))block;
- (void)rd_each: (nonnull void (^)(id _Nonnull obj))block;
- (nonnull NSArray *)rd_distinct;
- (nullable ObjectType)rd_randomItem;

@end
