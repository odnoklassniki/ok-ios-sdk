
#import <UIKit/UIKit.h>

@protocol OKSessionDelegate;

@interface OKAuthorizeController : UIViewController <UIWebViewDelegate>
+ (UIViewController *)authorizeControllerWithAppId:(NSString *)appId authorizationUrl:(NSURL *)authorizationUrl delegate:(id<OKSessionDelegate>)delegate;
@end