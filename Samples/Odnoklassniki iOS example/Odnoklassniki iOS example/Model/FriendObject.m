//
//  FriendObject.m
//  Odnoklassniki iOS example
//

#import "FriendObject.h"

@implementation FriendObject

- (id)initWithData:(NSDictionary *)data {
    self = [super initWithData:data];
    if (self) {
        self.online = data[@"online"]!=nil;
    }
    
    return self;
}

@end
