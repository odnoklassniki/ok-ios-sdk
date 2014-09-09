
#import "LoggedUserObject.h"


@interface LoggedUserObject ()
@property (nonatomic, copy, readwrite) NSString *country;
@end

@implementation LoggedUserObject
- (id)initWithData:(NSDictionary *)data {
    self = [super initWithData:data];
    if (self) {
        _country = data[@"location"][@"country"];
    }
    return self;
}
@end