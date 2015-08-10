
#import "Odnoklassniki.h"

@interface Odnoklassniki ()
@property (nonatomic, strong, readwrite) OKSession *session;
@property (nonatomic, copy, readwrite) NSString *appId;
@property (nonatomic, copy, readwrite) NSString *appSecret;
@property (nonatomic, copy, readwrite) NSString *appKey;
@end

@implementation Odnoklassniki

/**
* Initializes Odnoklassniki object
* @param appId application ID
* @param appSecret application SECRET
* @param appKey application KEY
* @param delegate OKSessionDelegate
*/
- (id)initWithAppId:(NSString *)appId
          appSecret:(NSString *)appSecret
             appKey:(NSString *)appKey
           delegate:(id<OKSessionDelegate>)delegate {

	self = [super init];
	if (self) {
		self.appId = appId;
		self.appSecret = appSecret;
		self.appKey = appKey;
		self.delegate = delegate;
	}
	return self;
}

- (void)dealloc {
    [self.session close];
    [OKSession setActiveSession:nil];
}

/**
* Authorize the application with permissions
* @param permissions comma-separated permissions scope (VALUABLE ACCESS, SET STATUS, PHOTO CONTENT)
*/
- (void)authorizeWithPermissions:(NSArray *)permissions inApp:(BOOL)inApp {
    [self.session close];
    self.session = [[OKSession alloc] initWithAppID:self.appId permissions:permissions appSecret:self.appSecret];
    self.session.delegate = self.delegate;
    self.session.appKey = self.appKey;
    [OKSession setActiveSession:self.session];
    [self.session authorizeInApp:inApp];
}

- (void)authorizeWithPermissions:(NSArray *)permissions {
    [self authorizeWithPermissions:permissions inApp:YES];
}

/**
* Refresh token if session has expired
*/
- (void)refreshToken {
    self.session.delegate = self.delegate;
	[self.session refreshAuthToken];
}

/**
* Invalidate the current user session by removing the access token in memory
* and calls OKSessionDelegate's method okDidLogout
*/
- (void)logout {
	[self.session close];
	[OKSession setActiveSession:nil];
	self.session = nil;

    NSArray *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies];
    for (NSHTTPCookie *cookie in cookies) {
        if (NSNotFound != [cookie.domain rangeOfString:@"odnoklassniki.ru"].location || NSNotFound != [cookie.domain rangeOfString:@"ok.ru"].location) {
            [[NSHTTPCookieStorage sharedHTTPCookieStorage]
                                  deleteCookie:cookie];
        }
    }


	if ([self.delegate respondsToSelector:@selector(okDidLogout)]) {
        [self.delegate okDidLogout];
    }
}

/**
 * @return boolean - whether this object has an non-expired session token
 */
- (BOOL)isSessionValid {
	if (!self.session) {
		BOOL activeSessionOpened = [OKSession openActiveSessionWithPermissions:nil appId:self.appId appSecret:self.appSecret];
        if (activeSessionOpened) {
            self.session = [OKSession activeSession];
            self.session.appKey = self.appKey;
        }
	}
	return self.session.accessToken != nil;
}

/**
 * Make a request to Odnoklassniki's REST API with the given method name and parameters.
 * @param methodName REST server API method (list of methods http://dev.odnoklassniki.ru/wiki/display/ok/Odnoklassniki+Rest+API).
 * @param params Key-value pairs of parameters to the request.
 * @param delegate Callback interface for notifying the calling application when the request has received responseData.
 * @return OKRequest Returns a pointer to the OKRequest object.
*/
+ (OKRequest *)requestWithMethodName:(NSString *)methodName
                              params:(NSDictionary *)params
                            delegate:(id <OKRequestDelegate>)delegate {
    return [OKRequest requestWithParams:params httpMethod:@"GET" delegate:delegate apiMethod:methodName];
}

+ (OKRequest *)requestWithMethodName:(NSString *)methodName params:(NSDictionary *)params {
    return [OKRequest requestWithParams:params httpMethod:@"GET" apiMethod:methodName];;
}

+ (OKRequest *)requestWithMethodName:(NSString *)methodName
                              params:(NSDictionary *)params
                          httpMethod:(NSString *)httpMethod
                            delegate:(id <OKRequestDelegate>)delegate {
    return [OKRequest requestWithParams:params httpMethod:httpMethod delegate:delegate apiMethod:methodName];
}

@end
