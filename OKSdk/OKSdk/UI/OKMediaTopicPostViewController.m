
#import "OKMediaTopicPostViewController.h"
#import "NSString+OKUtils.h"
#import "OKSession.h"

@interface OKMediaTopicPostViewController()
@property (nonatomic, copy) NSDictionary *attachments;
@property (nonatomic, copy) NSString *returnUrl;

@property (nonatomic, strong) UIWebView *webView;
@property (nonatomic, assign) BOOL finished;
@property (nonatomic, strong) NSURLRequest *request;

@property (nonatomic, copy) NSString *postSignature;
@end

#define OKColor [UIColor colorWithRed:0xED/255.f green:0x81/255.f blue:0x2B/255.f alpha:1.f]

@implementation OKMediaTopicPostViewController

+ (instancetype)postViewControllerWithAttachments:(NSDictionary *)attachments {
    OKSession *session = [OKSession activeSession];

    OKMediaTopicPostViewController *vc = [OKMediaTopicPostViewController new];
    vc.attachments = attachments;
    vc.returnUrl = [NSString stringWithFormat:@"ok%@://post", session.appId];
    return vc;
}

- (void)presentInViewController:(UIViewController *)viewController {
    UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:self];

    if ([nc.navigationBar respondsToSelector:@selector(barTintColor)]) {
        nc.navigationBar.barTintColor = OKColor;
        nc.navigationBar.tintColor = [UIColor whiteColor];
        nc.navigationBar.translucent = YES;
    } else {
        nc.navigationBar.tintColor = OKColor;
    }
    nc.navigationBar.titleTextAttributes = @{UITextAttributeTextColor : [UIColor whiteColor]};
    nc.modalPresentationStyle = UIModalPresentationFormSheet;
    [viewController presentViewController:nc animated:YES completion:nil];
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

    OKSession *session = [OKSession activeSession];

    NSString *attachments = [self attachmentFromDictionary:self.attachments];
    self.postSignature = [self signatureWith:attachments secret:session.appSecret returnUrl:self.returnUrl];
    NSURL *url = [self makeURLWithAppId:session.appId attachments:attachments signature:self.postSignature returnUrl:self.returnUrl];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [self.webView loadRequest:request];
}

#pragma mark - UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    self.request = request;

    if ([request.URL.absoluteString hasPrefix:self.returnUrl]) {
        return [self handleReturnURL:request.URL];
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

- (BOOL)handleReturnURL:(NSURL *)url {
    NSDictionary *d = [url.query dictionaryByParsingURLQueryPart];
    NSString *result = d[@"result"];
    if (result.length) {
        NSData *data = [result dataUsingEncoding:NSUTF8StringEncoding];
        NSError *error;
        NSDictionary *resultDictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];

        if (!resultDictionary) {
            [self cancel];
            return NO;
        }

        if ([resultDictionary[@"type"] isEqualToString:@"success"]) {
            [self finishWithError:nil];

// todo
//            NSString *id = resultDictionary[@"id"];
//            NSString *sig = [resultDictionary[@"signature"] lowercaseString];
//            NSString *sig2 = [[[NSString stringWithFormat:@"id=%@%@", id, self.postSignature] md5] lowercaseString];
//
//            if ([sig isEqualToString:sig2]) {
//            } else {
//                [self finishWithError:[self errorWithCode:9999 message:@"Unknown error"]];
//            }

            return NO;
        }

        NSNumber *code = resultDictionary[@"code"];
        if (code) {
            NSInteger errorCode = code.intValue;
            if (errorCode == 12) {
                [self cancel];
            } else {
                [self finishWithError:[self errorWithCode:errorCode message:resultDictionary[@"message"]]];
            }
        }
    }

    return NO;
}

- (NSError *)errorWithCode:(NSInteger)code message:(NSString *)message {
    NSDictionary *details = message.length ? @{NSLocalizedDescriptionKey :message} : nil;
    return [NSError errorWithDomain:OKApiErrorDomain code:code userInfo:details];
}

- (void)finishWithError:(NSError *)error {
    self.finished = YES;

    if (self.resultBlock) {
        self.resultBlock(error == nil, NO, error);
    } else {
        [self dismiss];
    }
}

- (void)cancel {
    self.finished = YES;

    if (self.resultBlock) {
        self.resultBlock(NO, YES, nil);
    } else {
        [self dismiss];
    }
}

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


#pragma mark -

- (NSString *)attachmentFromDictionary:(NSDictionary *)attachments {
    NSError *error = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:attachments options:0 error:&error];
    if (!data) {
        return nil;
    }

    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

- (NSString *)signatureWith:(NSString *)attachment secret:(NSString *)secret returnUrl:(NSString *)returnUrl {
    NSString *sig = [NSString stringWithFormat:@"st.attachment=%@st.return=%@%@", attachment, returnUrl, secret];
    return [[sig md5] lowercaseString];

}

- (NSURL *)makeURLWithAppId:(NSString *)appId attachments:(NSString *)attachments signature:(NSString *)signature returnUrl:(NSString *)returnUrl {
    NSString *url = [NSString stringWithFormat:@"http://connect.ok.ru/dk?st.cmd=WidgetMediatopicPost&"
                                                       "st.app=%@&st.attachment=%@&st.signature=%@&st.return=%@&st.popup=on",
                                               appId, [attachments URLEncodedString], signature, [returnUrl URLEncodedString]];

    return [NSURL URLWithString:url];
}

@end