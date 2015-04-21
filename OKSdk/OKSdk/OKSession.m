
#import "OKSession.h"
#import "OKTokenCache.h"
#import "NSString+OKUtils.h"
#import "OKAuthorizeController.h"

NSString * const kLoginURL = @"http://www.odnoklassniki.ru/oauth/authorize";
NSString * const kAccessTokenURL = @"http://api.odnoklassniki.ru/oauth/token.do";
NSString * const kAPIBaseURL = @"http://api.odnoklassniki.ru/api/";

static NSString * const OKAppAuthBaseURL = @"okauth://authorize";

static OKSession *_activeSession = nil;

@interface OKSession()
@property (nonatomic, strong) OKRequest *tokenRequest;
@property (nonatomic, strong) OKRequest *refreshTokenRequest;
@end

@implementation OKSession

+ (OKSession *)activeSession {
	if (!_activeSession) {
		[OKSession setActiveSession:[OKSession new]];
	}
	return _activeSession;
}

+ (OKSession *)setActiveSession:(OKSession *)session {
	if (!_activeSession) {
		_activeSession = session;
	} else if (session != _activeSession) {
        [_activeSession close];
		_activeSession = session;
	}
	return session;
}

+ (BOOL)openActiveSessionWithPermissions:(NSArray *)permissions appId:(NSString *)appID appSecret:(NSString *)secret{
	BOOL result = NO;
	OKSession *session = [[OKSession alloc] initWithAppID:appID permissions:permissions appSecret:secret];
	if (session.accessToken != nil) {
		[self setActiveSession:session];
		result = YES;
	}
	return result;
}

- (id)initWithAppID:(NSString *)appID permissions:(NSArray *)permissions appSecret:(NSString *)secret {
    self = [super init];
    if (self){
        self.appId = appID;
        self.permissions = permissions;
        self.appSecret = secret;

        NSDictionary *cachedToken = [[OKTokenCache sharedCache] tokenInfo];
        if (cachedToken) {
            self.accessToken = [cachedToken valueForKey:kOKAccessTokenKey];
            self.refreshToken = [NSString stringWithFormat:@"%@", [cachedToken valueForKey:kOKRefreshTokenKey]];

            NSArray *cachedPermissions = [cachedToken valueForKey:kOKPermissionsKey];
            if (self.permissions == nil) {
                self.permissions = cachedPermissions;
            }

            if (![self.permissions isEqualToArray:cachedPermissions]){
                self.accessToken = nil;
                self.refreshToken = nil;
            }
        }
    }
    return self;
}

- (BOOL)canHandleOpenURL:(NSURL *)url {
    if (![[url absoluteString] hasPrefix:self.appBaseUrl]) {
        NSLog(@"wrong prefix = %@, %@", [url absoluteString], self.appBaseUrl);
        return NO;
    }
    return YES;
}

- (BOOL)handleOpenURL:(NSURL *)url {
    if (![self canHandleOpenURL:url]) {
        return NO;
    }
    
	NSDictionary *params = [url.query dictionaryByParsingURLQueryPart];

	if ([params valueForKey:@"error"] != nil) {
		if ([[params valueForKey:@"error"] isEqualToString:@"access_denied"]) {
			[self didNotLogin:YES];
		} else if ([self.delegate respondsToSelector:@selector(okDidNotLoginWithError:)]) {
            [self.delegate okDidNotLoginWithError:[NSError errorWithDomain:@"Odnoklassniki.ru" code:511 userInfo:params]];
        }
		return YES;
	}

	NSString *code = params[@"code"];

	NSMutableDictionary *newParams = [NSMutableDictionary dictionary];
	[newParams setValue:code forKey:@"code"];
	[newParams setValue:[self.permissions componentsJoinedByString:@","] forKey:@"permissions"];
    [newParams setValue:self.appBaseUrl forKey:@"redirect_uri"];
	[newParams setValue:@"authorization_code" forKey:@"grant_type"];
	[newParams setValue:self.appId forKey:@"client_id"];
	[newParams setValue:self.appSecret forKey:@"client_secret"];

	self.tokenRequest = [OKRequest new];
	self.tokenRequest.url = [OKRequest serializeURL:kAccessTokenURL params:newParams];
	self.tokenRequest.delegate = self;
	self.tokenRequest.params = newParams;
	self.tokenRequest.httpMethod = @"POST";
	[self.tokenRequest load];

	return YES;
}

- (void)close {
	[[OKTokenCache sharedCache] clearToken];
}

- (void)authorize {
    [self authorizeInApp:YES];
}

- (void)authorizeInApp:(BOOL)inApp {
    if (self.accessToken) {
        if ([self.delegate respondsToSelector:@selector(okDidLogin)]) {
            [self.delegate okDidLogin];
        }
        return;
    }

    NSMutableDictionary *params = [NSMutableDictionary new];
    params[@"client_id"] = self.appId;
    params[@"redirect_uri"] = [self appBaseUrl];
    params[@"response_type"] = @"code";

    if (self.permissions.count) {
        params[@"scope"] = [self.permissions componentsJoinedByString:@";"];
    }

    UIApplication *app = [UIApplication sharedApplication];

    NSURL *authorizeUrl = [NSURL URLWithString:[OKRequest serializeURL:OKAppAuthBaseURL params:params]];
    NSURL *callbackUrl = [NSURL URLWithString:[self appBaseUrl]];
    if ([app canOpenURL:authorizeUrl] && [app canOpenURL:callbackUrl]) {
        if ([app openURL:authorizeUrl]) {
            return;
        }
    }

    if (inApp) {
        params[@"layout"] = @"a";
        authorizeUrl = [NSURL URLWithString:[OKRequest serializeURL:kLoginURL params:params]];
        UIViewController *ac = [OKAuthorizeController authorizeControllerWithAppId:self.appId
                                                                  authorizationUrl:authorizeUrl
                                                                          delegate:self.delegate];
        [self.delegate okShouldPresentAuthorizeController:ac];
    } else {
        params[@"layout"] = @"m";
        authorizeUrl = [NSURL URLWithString:[OKRequest serializeURL:kLoginURL params:params]];
        [app openURL:authorizeUrl];
    }
}

- (NSString *)appBaseUrl {
	return [NSString stringWithFormat:@"ok%@://authorize", self.appId];
}

- (void)refreshAuthToken {
	NSMutableDictionary *newParams = [NSMutableDictionary dictionary];
    newParams[@"client_id"] = self.appId;
    newParams[@"client_secret"] = self.appSecret;
    newParams[@"refresh_token"] = self.refreshToken;
    newParams[@"grant_type"] = @"refresh_token";

	self.refreshTokenRequest = [OKRequest new];
	self.refreshTokenRequest.url = [OKRequest serializeURL:kAccessTokenURL params:newParams];
	self.refreshTokenRequest.delegate = self;
	self.refreshTokenRequest.params = newParams;
	self.refreshTokenRequest.httpMethod = @"POST";
	[self.refreshTokenRequest load];
}

- (void)cacheTokenCacheWithPermissions:(NSDictionary *)tokenInfo {
	NSMutableDictionary *dct = [tokenInfo mutableCopy];
	[dct setValue:self.permissions forKey:kOKPermissionsKey];
	[[OKTokenCache sharedCache] cacheTokenInformation:dct];
}

- (void)didNotLogin:(BOOL)canceled {
	if ([self.delegate respondsToSelector:@selector(okDidNotLogin:)]) {
        [self.delegate okDidNotLogin:canceled];
    }
}

- (void)didNotExtendToken:(NSError *)error {
	if ([self.delegate respondsToSelector:@selector(okDidNotExtendToken:)]) {
        [self.delegate okDidNotExtendToken:error];
    }
}

#pragma mark -  OKAPIRequest delegate only for authorization

- (void)request:(OKRequest *)request didLoad:(id)result {
	if (request == self.tokenRequest) {
		if (request.hasError) {
			[self didNotLogin:NO];
			return;
		}
        [self cacheTokenCacheWithPermissions:result];
		self.accessToken = [(NSDictionary *)result valueForKey:kOKAccessTokenKey];
		self.refreshToken = [(NSDictionary *)result valueForKey:kOKRefreshTokenKey];

		if ([self.delegate respondsToSelector:@selector(okDidLogin)]) {
            [self.delegate okDidLogin];
        }

	} else if (request == self.refreshTokenRequest) {
		if (self.refreshTokenRequest.hasError) {
			[self didNotExtendToken:nil];
			return;
		}

		NSMutableDictionary *dct = [NSMutableDictionary dictionaryWithDictionary:[[OKTokenCache sharedCache] tokenInfo]];
		self.accessToken = [(NSDictionary *)result valueForKey:kOKAccessTokenKey];
		[dct setValue:self.accessToken forKey:kOKAccessTokenKey];
        [self cacheTokenCacheWithPermissions:dct];
		if ([self.delegate respondsToSelector:@selector(okDidExtendToken:)]) {
            [self.delegate okDidExtendToken:self.accessToken];
        }
	}
}

- (void)request:(OKRequest *)request didFailWithError:(NSError *)error {
    if (request == self.tokenRequest) {
        if (request.sessionExpired) {
            [self refreshAuthToken];
        } else {
            [self didNotLogin:NO];
        }
    } else if (request == self.refreshTokenRequest) {
        [self didNotExtendToken:error];
    }
}

@end