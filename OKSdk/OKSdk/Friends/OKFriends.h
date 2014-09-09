
#import <Foundation/Foundation.h>
#import "Odnoklassniki.h"

@interface OKFriends : NSObject

+ (void)inviteFriends:(NSArray *)friendsIds
               forUid:(NSString *)userId
       invitationText:(NSString *)text
              devices:(NSString *)devices
             delegate:(id<OKRequestDelegate>)delegate;

@end
