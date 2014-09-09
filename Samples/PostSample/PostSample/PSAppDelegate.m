//
//  PSAppDelegate.m
//  PostSample
//

#import "PSAppDelegate.h"
#import "Odnoklassniki.h"
#import "PSPostViewController.h"
#import "PSLoginController.h"

NSString * const appId = @"<app id>";
NSString * const appKey = @"<app key>";
NSString * const appSecret = @"<secret key>";

@interface PSAppDelegate () <OKSessionDelegate>
@property (nonatomic, strong, readwrite) Odnoklassniki *okApi;
@end

@implementation PSAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    // API initialization
    // инициализация API
    self.okApi = [[Odnoklassniki alloc] initWithAppId:appId
                                            appSecret:appSecret
                                               appKey:appKey
                                             delegate:self];

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

    NSArray *vcs = self.okApi.isSessionValid
                   ? @[[PSLoginController new], [PSPostViewController new]]
                   : @[[PSLoginController new]] ;

    UINavigationController *nc = [UINavigationController new];
    [nc setViewControllers:vcs];

    self.window.rootViewController = nc;
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    return YES;
}

#pragma mark -

- (void)okShouldPresentAuthorizeController:(UIViewController *)viewController {
    [self.window.rootViewController presentViewController:viewController animated:YES completion:nil];
}

- (void)okDidLogin {
    if ([self.rootNavigationController.topViewController isKindOfClass:[PSLoginController class]]) {
        PSPostViewController *pvc = [PSPostViewController new];
        [self.rootNavigationController pushViewController:pvc animated:YES];
    }
}

- (void)okDidNotLoginWithError:(NSError *)error {
    [self showAlertWithError:error];
}
- (void)okDidNotExtendToken:(NSError *)error {
    [self showAlertWithError:error];
}

- (void)okDidExtendToken:(NSString *)accessToken {

}

- (void)okDidLogout {
    [self.rootNavigationController popToRootViewControllerAnimated:YES];
}


#pragma mark - Helpers

+ (PSAppDelegate *)appDelegate {
    return [UIApplication sharedApplication].delegate;
}

- (UINavigationController *)rootNavigationController {
    return (UINavigationController *) self.window.rootViewController;
}

- (void)showAlertWithError:(NSError *)error {
    [[[UIAlertView alloc] initWithTitle:@"Error"
                                message:error.localizedDescription
                               delegate:nil
                      cancelButtonTitle:@"OK"
                      otherButtonTitles:nil] show];
}

@end
