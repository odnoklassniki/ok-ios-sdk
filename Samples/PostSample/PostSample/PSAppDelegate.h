//
//  PSAppDelegate.h
//  PostSample
//

#import <UIKit/UIKit.h>

@class Odnoklassniki;

@interface PSAppDelegate : UIResponder <UIApplicationDelegate>

@property (nonatomic, strong) UIWindow *window;
@property (nonatomic, strong, readonly) Odnoklassniki *okApi;

+ (PSAppDelegate *)appDelegate;

@end
