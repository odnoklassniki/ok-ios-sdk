
#import <Foundation/Foundation.h>
#import "OKSession.h"

@interface Odnoklassniki : NSObject<OKSessionDelegate>
@property (nonatomic, weak) id <OKSessionDelegate> delegate;

@property (nonatomic, strong, readonly) OKSession *session;
@property (nonatomic, copy, readonly) NSString *appId;
@property (nonatomic, copy, readonly) NSString *appSecret;
@property (nonatomic, copy, readonly) NSString *appKey;

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
           delegate:(id<OKSessionDelegate>)delegate;

/**
* Authorize the application with permissions
* @param permissions comma-separated permissions scope (VALUABLE ACCESS, SET STATUS, PHOTO CONTENT)
*/
- (void)authorizeWithPermissions:(NSArray *)permissions;

/**
* Refresh token if session has expired
*/
- (void)refreshToken;

/**
* Invalidate the current user session by removing the access token in memory
* and calls OKSessionDelegate's method okDidLogout
*/
- (void)logout;

/**
* @return boolean - whether this object has an non-expired session token
*/
- (BOOL)isSessionValid;

/**
* Make a request to Odnoklassniki's REST API with the given method name and parameters.
* @param methodName REST server API method (list of methods http://dev.odnoklassniki.ru/wiki/display/ok/Odnoklassniki+Rest+API).
* @param params Key-value pairs of parameters to the request.
* @param delegate Callback interface for notifying the calling application when the request has received responseData.
* @return OKRequest Returns a pointer to the OKRequest object.
*/
+ (OKRequest *)requestWithMethodName:(NSString *)methodName
                              params:(NSDictionary *)params
                          httpMethod:(NSString *)httpMethod
                            delegate:(id<OKRequestDelegate>)delegate;

+ (OKRequest *)requestWithMethodName:(NSString *)methodName
                              params:(NSDictionary *)params
                            delegate:(id<OKRequestDelegate>)delegate;

+ (OKRequest *)requestWithMethodName:(NSString *)methodName
                              params:(NSDictionary *)params;

@end