
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "OKRequest.h"

extern NSString * const kLoginURL;
extern NSString * const kAccessTokenURL;
extern NSString * const kAPIBaseURL;

@protocol OKSessionDelegate<NSObject>
@optional
- (void)okDidLogin;
- (void)okShouldPresentViewController:(UIViewController *)viewController;
- (void)okDidNotLogin:(BOOL)canceled;
- (void)okDidNotLoginWithError:(NSError *)error;
- (void)okDidExtendToken:(NSString *)accessToken;
- (void)okDidNotExtendToken:(NSError *)error;
- (void)okDidLogout;
@end

@interface OKSession : NSObject<OKRequestDelegate>

@property (nonatomic, copy) NSString *appId;
@property (nonatomic, copy) NSString *appSecret;
@property (nonatomic, copy) NSString *appKey;

@property (nonatomic, copy) NSString *accessToken;
@property (nonatomic, copy) NSString *refreshToken;
@property (nonatomic, strong) NSArray *permissions;

@property (nonatomic, weak) id <OKSessionDelegate> delegate;


+ (OKSession *)activeSession;
+ (OKSession *)setActiveSession:(OKSession *)session;

+ (BOOL)openActiveSessionWithPermissions:(NSArray *)permissions appId:(NSString *)appID appSecret:(NSString *)secret;

- (id)initWithAppID:(NSString *)appID permissions:(NSArray *)permissions appSecret:(NSString*)secret;

- (void)authorize;
- (void)authorizeInApp:(BOOL)inApp;

- (void)refreshAuthToken;

- (BOOL)handleOpenURL:(NSURL*)url;
- (void)close;

@end