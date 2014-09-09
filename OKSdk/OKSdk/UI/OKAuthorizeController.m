
#import "OKAuthorizeController.h"
#import "OKSession.h"

#define OKColor [UIColor colorWithRed:0xED/255.f green:0x81/255.f blue:0x2B/255.f alpha:1.f]

@interface OKAuthorizeController()<UIAlertViewDelegate>
@property (nonatomic, strong) NSURL *authorizationUrl;
@property (nonatomic, copy) NSString *appId;

@property (nonatomic, copy) NSString *redirectUrlScheme;

@property (nonatomic, strong) UIWebView *webView;
@property (nonatomic, assign) BOOL finished;
@property (nonatomic, strong) NSURLRequest *request;

@property (nonatomic, weak) id<OKSessionDelegate> delegate;
@end

@implementation OKAuthorizeController

+ (UIViewController *)authorizeControllerWithAppId:(NSString *)appId authorizationUrl:(NSURL *)authorizationUrl delegate:(id<OKSessionDelegate>)delegate {
    OKAuthorizeController *ac = [[OKAuthorizeController alloc] initWithAppId:appId authorizationUrl:authorizationUrl];
    ac.delegate = delegate;

    UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:ac];

    if ([nc.navigationBar respondsToSelector:@selector(barTintColor)]) {
        nc.navigationBar.barTintColor = OKColor;
        nc.navigationBar.tintColor = [UIColor whiteColor];
        nc.navigationBar.translucent = YES;
    } else {
        nc.navigationBar.tintColor = OKColor;
    }
    nc.navigationBar.titleTextAttributes = @{UITextAttributeTextColor : [UIColor whiteColor]};

    return nc;
}

- (instancetype)initWithAppId:(NSString *)appId authorizationUrl:(NSURL *)authorizationUrl {
    self = [super init];
    if (self) {
        self.appId = appId;
        self.authorizationUrl = authorizationUrl;
        self.redirectUrlScheme = [NSString stringWithFormat:@"ok%@", self.appId];
    }
    return self;
}

- (void)dealloc {
    self.webView.delegate = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"Odnoklassniki";

    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                          target:self
                                                                                          action:@selector(cancel)];

    self.webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
    self.webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.webView.delegate = self;
    [self.view addSubview:self.webView];

    NSURLRequest *request = [NSURLRequest requestWithURL:self.authorizationUrl];
    [self.webView loadRequest:request];
}

#pragma mark - UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    self.request = request;

    if ([request.URL.scheme isEqualToString:self.redirectUrlScheme]) {
        if ([[OKSession activeSession] handleOpenURL:request.URL]) {
            [self dismissByCancel:NO];
            return NO;
        }
    }

    return YES;
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    if (self.finished || error.code == NSURLErrorCancelled) {
        return;
    }

    [[[UIAlertView alloc] initWithTitle:nil
                                message:@"No internet connection available"
                               delegate:self
                      cancelButtonTitle:@"Cancel"
                      otherButtonTitles:@"Repeat", nil] show];

}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == alertView.cancelButtonIndex) {
        [self cancel];
    } else {
        [self.webView loadRequest:self.request];
    }
}

#pragma mark - Actions

- (void)cancel {
    [self dismissByCancel:YES];
}

- (void)dismissByCancel:(BOOL)byCancel {
    self.finished = YES;

    if (self.navigationController.isBeingDismissed)
        return;

    if (!self.navigationController.isBeingPresented) {
        if ([self.delegate respondsToSelector:@selector(okWillDismissAuthorizeControllerByCancel:)]) {
            [self.delegate okWillDismissAuthorizeControllerByCancel:byCancel];
        }

        [self.navigationController.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    } else {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(300 * NSEC_PER_MSEC)), dispatch_get_main_queue(), ^(void) {
            [self dismissByCancel:byCancel];
        });
    }
}

#pragma mark - UIViewController

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

@end