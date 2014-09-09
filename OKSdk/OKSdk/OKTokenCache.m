
#import "OKTokenCache.h"

static NSString * const OKTokenKey = @"ru.odnoklassniki.sdk:TokenKey";

NSString * const kOKAccessTokenKey = @"access_token";
NSString * const kOKRefreshTokenKey = @"refresh_token";
NSString * const kOKPermissionsKey = @"permissions";

@implementation OKTokenCache

+ (OKTokenCache *)sharedCache {
    static OKTokenCache *sharedCache = nil;

    static dispatch_once_t pred;
    dispatch_once(&pred, ^{
        sharedCache = [OKTokenCache new];
    });

    return sharedCache;
}

- (void)cacheTokenInformation:(NSDictionary *)tokenInfo {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setObject:tokenInfo forKey:OKTokenKey];
	[defaults synchronize];
}

- (NSDictionary *)tokenInfo {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	return [defaults objectForKey:OKTokenKey];
}

- (void)clearToken {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults removeObjectForKey:OKTokenKey];
	[defaults synchronize];
}

@end