
#import <UIKit/UIKit.h>

@interface OKAuthorizeController : UIViewController <UIWebViewDelegate>
+ (UIViewController *)authorizeControllerWithAppId:(NSString *)appId authorizationUrl:(NSURL *)authorizationUrl;
@end