
#import "PSPostViewController.h"
#import "PSAppDelegate.h"
#import "Odnoklassniki.h"
#import "OKMediaTopicPostViewController.h"

@interface PSPostViewController() <UITextViewDelegate>
@property (nonatomic, strong) UITextView *textView;
@end

@implementation PSPostViewController

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    if ([self respondsToSelector:@selector(edgesForExtendedLayout)]) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }

    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Logout"
                                                                             style:UIBarButtonItemStyleDone
                                                                            target:self
                                                                            action:@selector(logout)];

    self.textView = [[UITextView alloc] initWithFrame:self.view.bounds];
    self.textView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.textView.delegate = self;
    [self.view addSubview:self.textView];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didReceiveKeyboardWillShowNotification:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];

}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    [self.textView becomeFirstResponder];
}

#pragma mark - UITextViewDelegate

- (void)textViewDidChange:(UITextView *)textView {
    if (textView.text.length) {
        [self enableRightButton];
    } else {
        [self disableRightButton];
    }
}

#pragma mark -

- (void)disableRightButton {
    self.navigationItem.rightBarButtonItem = nil;
}

- (void)enableRightButton {
    if (!self.navigationItem.rightBarButtonItem) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Post"
                                                                                  style:UIBarButtonItemStyleDone
                                                                                 target:self
                                                                                 action:@selector(post)];
    }
}

#pragma mark - Keyboard observing

- (void)didReceiveKeyboardWillShowNotification:(NSNotification *)notification {
    NSDictionary *userInfo = [notification userInfo];

    CGRect keyboardRect = [userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];

    CGPoint origin = [self.view.window convertPoint:self.textView.frame.origin fromView:self.textView];

    UIInterfaceOrientation orientation = self.interfaceOrientation;

    CGFloat popupViewHeight = 0;
    switch (orientation) {
        case UIInterfaceOrientationPortrait:
            popupViewHeight = keyboardRect.origin.y - origin.y;
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            popupViewHeight = origin.y - keyboardRect.size.height;
            break;
        case UIInterfaceOrientationLandscapeLeft:
            popupViewHeight = keyboardRect.origin.x - origin.x;
            break;
        case UIInterfaceOrientationLandscapeRight:
            popupViewHeight = origin.x - keyboardRect.size.width;
            break;
        default:
            break;
    }

    CGRect frame = self.textView.bounds;
    frame.size.height = popupViewHeight;
    self.textView.frame = frame;
}

#pragma mark - Actions

- (void)post {
    if (!self.textView.text.length) {
        return;
    }

    NSDictionary *attachments = @{
        @"media" : @[@{@"text" : self.textView.text, @"type" : @"text"}]
    };


    OKMediaTopicPostViewController *pvc = [OKMediaTopicPostViewController postViewControllerWithAttachments:attachments];
    [pvc presentInViewController:self];

    __weak __typeof (self)wSelf = self;
    pvc.resultBlock = ^(BOOL result, BOOL canceled, NSError *error) {
        if (!canceled) {
            [[[UIAlertView alloc] initWithTitle:result ? @"Success" : @"Error"
                                        message:error.localizedDescription
                                       delegate:nil
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil] show];
        }
        [wSelf dismissViewControllerAnimated:YES completion:nil];
    };
}

- (void)logout {
    [[PSAppDelegate appDelegate].okApi logout];
}

@end