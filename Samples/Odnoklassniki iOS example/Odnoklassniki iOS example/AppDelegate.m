//
//  AppDelegate.m
//  Odnoklassniki iOS example
//

#import "AppDelegate.h"
#import "OKSession.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    return YES;
}
							
// add this for authorizing via SDK
// добавьте этот код для корректной работы авторизации через SDK

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation
{
    return [OKSession.activeSession handleOpenURL:url];
}

@end
