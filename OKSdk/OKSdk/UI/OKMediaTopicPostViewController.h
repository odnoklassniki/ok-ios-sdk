
#import <UIKit/UIKit.h>

@interface OKMediaTopicPostViewController : UIViewController <UIWebViewDelegate>
@property (nonatomic, copy) void (^resultBlock)(BOOL result, BOOL canceled, NSError *error);

+ (instancetype)postViewControllerWithAttachments:(NSDictionary *)attachments;
- (void)presentInViewController:(UIViewController *)viewController;
@end