
#import <Foundation/Foundation.h>

extern NSString *const kOKAccessTokenKey;
extern NSString *const kOKRefreshTokenKey;
extern NSString *const kOKPermissionsKey;

@interface OKTokenCache : NSObject

+ (OKTokenCache *)sharedCache;

- (void)cacheTokenInformation:(NSDictionary *)tokenInfo;
- (NSDictionary *)tokenInfo;
- (void)clearToken;

@end