
#import "OKFriends.h"

@implementation OKFriends

/**
* Inviting friends to application
* http://dev.odnoklassniki.ru/wiki/display/ok/REST+API+-+friends.appInvite
* @param friendsIds (Required) - array of recipient friend ids
* @param userId - The user ID for the user whose friends you want to return. Specify the uid when calling this method without a session key.
* @param text - Invitation text.
* @param devices - Comma separated list of device groups on which the invitation will be shown. Currently supported groups: IOS, ANDROID, WEB.
*/

+ (void)inviteFriends:(NSArray *)friendsIds forUid:(NSString *)userId invitationText:(NSString *)text devices:(NSString *)devices delegate:(id <OKRequestDelegate>)delegate {
    NSString *userIds = [friendsIds componentsJoinedByString:@","];

    if (!userIds.length) {
        return;
    }

	NSMutableDictionary *params = [@{@"uids" : userIds} mutableCopy];
	if (userId.length) {
        params[@"uid"] = userId;
    }
	if (text.length) {
        params[@"text"] = text;
    }
	if (devices.length) {
        params[@"devices"] = devices;
    }

	OKRequest *request = [Odnoklassniki requestWithMethodName:@"friends.appInvite" params:params httpMethod:@"POST" delegate:delegate];
	[request load];
}


@end