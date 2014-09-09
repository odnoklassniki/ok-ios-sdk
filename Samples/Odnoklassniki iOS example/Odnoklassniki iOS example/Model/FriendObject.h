//
//  FriendObject.h
//  Odnoklassniki iOS example
//

#import <Foundation/Foundation.h>
#import "UserObject.h"

@interface FriendObject : UserObject
@property (nonatomic, assign, getter=isOnline) BOOL online;
@end
