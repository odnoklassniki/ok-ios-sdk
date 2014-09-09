
#import "PSLoginController.h"
#import "PSAppDelegate.h"
#import "Odnoklassniki.h"

@implementation PSLoginController

- (void)viewDidLoad {
    [super viewDidLoad];

    UIButton *loginButton = [UIButton new];
    [loginButton setTitle:@"Login" forState:UIControlStateNormal];
    [loginButton setTitleColor:[UIColor orangeColor] forState:UIControlStateNormal];
    [loginButton sizeToFit];
    loginButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin
            | UIViewAutoresizingFlexibleRightMargin
            | UIViewAutoresizingFlexibleTopMargin
            | UIViewAutoresizingFlexibleBottomMargin;
    loginButton.frame = CGRectOffset(loginButton.bounds,
            floorf((CGRectGetWidth(self.view.bounds) - CGRectGetWidth(loginButton.bounds)) / 2),
            floorf((CGRectGetHeight(self.view.bounds) - CGRectGetHeight(loginButton.bounds)) / 2));
    [self.view addSubview:loginButton];

    [loginButton addTarget:self action:@selector(login) forControlEvents:UIControlEventTouchUpInside];
}

- (void)login {
    [[PSAppDelegate appDelegate].okApi authorizeWithPermissions:@[@"VALUABLE ACCESS"]];
}

@end