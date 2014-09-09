
#import "OKAuthorizeController.h"
#import "OKSession.h"

@interface OKAuthorizeController()<UIAlertViewDelegate>
@property (nonatomic, strong) NSURL *authorizationUrl;
@property (nonatomic, copy) NSString *appId;

@property (nonatomic, copy) NSString *redirectUrlScheme;

@property (nonatomic, strong) UIWebView *webView;
@property (nonatomic, assign) BOOL finished;
@property (nonatomic, strong) NSURLRequest *request;
@end

@implementation OKAuthorizeController

+ (UIViewController *)authorizeControllerWithAppId:(NSString *)appId authorizationUrl:(NSURL *)authorizationUrl {
    OKAuthorizeController *ac = [[OKAuthorizeController alloc] initWithAppId:appId authorizationUrl:authorizationUrl];

    UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:ac];

    if ([nc.navigationBar respondsToSelector:@selector(barTintColor)]) {
        nc.navigationBar.barTintColor = [UIColor orangeColor];
        nc.navigationBar.tintColor = [UIColor whiteColor];
        nc.navigationBar.translucent = YES;
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
                                                                                          action:@selector(dismiss)];

    self.webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
    self.webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.webView.delegate = self;
    [self.view addSubview:self.webView];

    NSURLRequest *request = [NSURLRequest requestWithURL:self.authorizationUrl];
    [self.webView loadRequest:request];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self setNeedsStatusBarAppearanceUpdate];
}

#pragma mark - UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    self.request = request;

    if ([request.URL.scheme isEqualToString:self.redirectUrlScheme]) {
        if ([[OKSession activeSession] handleOpenURL:request.URL]) {
            [self dismiss];
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
        [self dismiss];
    } else {
        [self.webView loadRequest:self.request];
    }
}


#pragma mark - Actions

- (void)dismiss {
    self.finished = YES;

    if (self.navigationController.isBeingDismissed)
        return;
    if (!self.navigationController.isBeingPresented) {
        [self.navigationController.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    } else {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(300 * NSEC_PER_MSEC)), dispatch_get_main_queue(), ^(void) {
            [self dismiss];
        });
    }
}

#pragma mark - UIViewController

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

@end