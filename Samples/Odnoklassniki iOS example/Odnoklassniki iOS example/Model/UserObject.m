//
// Created by Ivanov Denis on 09.09.14.
// Copyright (c) 2014 Артем Лобачев. All rights reserved.
//



#import "UserObject.h"


@interface UserObject ()
@property (nonatomic, copy, readwrite) NSString *uid;
@property (nonatomic, copy, readwrite) NSString *name;
@property (nonatomic, copy, readwrite) NSString *surname;
@property (nonatomic, copy, readwrite) NSString *pic50x50;
@end

@implementation UserObject

- (id)initWithData:(NSDictionary *)data {
    self = [super init];
    if (self) {
        _uid = data[@"uid"];
        _name = data[@"first_name"];
        _surname = data[@"last_name"];
        _pic50x50 = data[@"pic50x50"];
    }
    return self;
}

- (NSString *)fullName {
    return [NSString stringWithFormat:@"%@ %@", self.name, self.surname];
}

@end