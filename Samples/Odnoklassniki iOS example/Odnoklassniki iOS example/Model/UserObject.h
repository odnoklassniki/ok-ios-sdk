
#import "ServerObject.h"

@interface UserObject : ServerObject
@property (nonatomic, copy, readonly) NSString *uid;
@property (nonatomic, copy, readonly) NSString *name;
@property (nonatomic, copy, readonly) NSString *surname;
@property (nonatomic, copy, readonly) NSString *pic50x50;

- (NSString *)fullName;
@end