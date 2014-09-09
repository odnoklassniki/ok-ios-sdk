
#import "ServerObject.h"


@implementation ServerObject

- (id)initWithData:(NSDictionary *)data {
    return [super init];
}

+ (NSArray *)objectsFromArray:(NSArray *)array {
    NSMutableArray *objects = [NSMutableArray new];
    for (NSDictionary *data in array) {
        ServerObject *object = [[[self class] alloc] initWithData:data];
        if (object) {
            [objects addObject:object];
        }
    }
    return objects;
}

@end