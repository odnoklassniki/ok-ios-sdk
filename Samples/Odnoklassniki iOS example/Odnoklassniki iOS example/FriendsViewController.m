//
//  FriendsViewController.m
//  Odnoklassniki iOS example
//

#import "FriendsViewController.h"
#import "Odnoklassniki.h"
#import "LoggedUserObject.h"
#import "ImageLoadingOperation.h"

@interface FriendsViewController ()<OKSessionDelegate, OKRequestDelegate,UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, weak) IBOutlet UILabel *sessionStatusLabel;
@property (nonatomic, weak) IBOutlet UIButton *authButton;
@property (nonatomic, weak) IBOutlet UITextField *nameTextField;
@property (nonatomic, weak) IBOutlet UITextField *surnameTextField;
@property (nonatomic, weak) IBOutlet UITextField *countryTextField;
@property (nonatomic, weak) IBOutlet UIImageView *photo;
@property (nonatomic, weak) IBOutlet UITableView *tableView;

@property (nonatomic, strong) Odnoklassniki *api;
@property (nonatomic, strong) NSArray *friends;

@property (nonatomic, strong) NSOperationQueue *queue;

@end

NSString * const appId = @"<app id>";
NSString * const appKey = @"<app key>";
NSString * const appSecret = @"<secret key>";

@implementation FriendsViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.queue = [NSOperationQueue new];
    [self.queue setMaxConcurrentOperationCount:8];

    [self.authButton addTarget:self action:@selector(loginButtonClick:) forControlEvents:UIControlEventTouchDown];

    // API initialization
    // инициализация API
	self.api = [[Odnoklassniki alloc] initWithAppId:appId appSecret:appSecret appKey:appKey delegate:self];

    // if access_token is valid
    // если access_token действителен
    if (self.api.isSessionValid) {
        self.sessionStatusLabel.text = @"Logged in";
        [self.authButton setTitle:@"Logout" forState:UIControlStateNormal];
        [self okDidLogin];
    } else {
        self.sessionStatusLabel.text = @"Not logged in";
        [self.authButton setTitle:@"Login" forState:UIControlStateNormal];
        [self.api refreshToken];
    }
}

#pragma mark - API requests

/*
* API request without params.
* Запрос к API без параметров.
*/
- (void)getFriends {
    OKRequest *newRequest = [Odnoklassniki requestWithMethodName:@"friends.get" params:nil];
    [newRequest executeWithCompletionBlock:^(NSArray *uids) {
        if (![uids isKindOfClass:[NSArray class]] || !uids.count) {
            return;
        }

        [self getUsersInfoWithUids:uids.count >= 100 ? [uids subarrayWithRange:NSMakeRange(0, 10)] : uids];
    } errorBlock:^(NSError *error) {
        NSLog(@"[%@ %@] %@", NSStringFromClass(self.class), NSStringFromSelector(_cmd), error);
    }];
}

/*
 * API request with params.
 * Запрос к API с параметрами.
 */
- (void)getUserInfo{
    OKRequest *newRequest = [Odnoklassniki requestWithMethodName:@"users.getCurrentUser" params:@{
            @"fields": @"first_name,last_name,location,pic50x50"
    }];
    [newRequest executeWithCompletionBlock:^(NSDictionary *data) {
        if (![data isKindOfClass:[NSDictionary class]]) {
            return;
        }

        LoggedUserObject *loggedUser = [[LoggedUserObject alloc] initWithData:data];

        self.surnameTextField.text = loggedUser.surname;
        self.nameTextField.text = loggedUser.name;
        self.countryTextField.text = loggedUser.country;

        ImageLoadingOperation *op = [ImageLoadingOperation operationWithImageURL:[NSURL URLWithString:loggedUser.pic50x50]
                                                                      completion:^(UIImage *image, NSURL *originalURL, NSError *error) {
                                                                          self.photo.image = image;
                                                                      }];
        [self.queue addOperation:op];
    } errorBlock:^(NSError *error) {
        NSLog(@"[%@ %@] %@", NSStringFromClass(self.class), NSStringFromSelector(_cmd), error);
    }];
}

- (void)getUsersInfoWithUids:(NSArray *)uids {
    if (!uids.count) {
        return;
    }

    OKRequest *request = [Odnoklassniki requestWithMethodName:@"users.getInfo" params:@ {
            @"uids": [uids componentsJoinedByString:@","],
            @"fields": @"uid,first_name,last_name,online,pic50x50"
    }];
    [request executeWithCompletionBlock:^(NSArray *friendsInfo) {
        self.friends = [FriendObject objectsFromArray:friendsInfo];
        [self.tableView reloadData];

    } errorBlock:^(NSError *error) {
        NSLog(@"[%@ %@] %@", NSStringFromClass(self.class), NSStringFromSelector(_cmd), error);
    }];

}

#pragma mark - Odnoklassniki Delegate methods

- (void)okShouldPresentAuthorizeController:(UIViewController *)viewController {
    [self presentViewController:viewController animated:YES completion:nil];
}

/*
* Method will be called after success login ([_api authorize:])
* Метод будет вызван после успешной авторизации ([_api authorize:])
*/



- (void)okDidLogin {
    self.sessionStatusLabel.text = @"Logged in";
    [self.authButton setTitle:@"Logout" forState:UIControlStateNormal];

    [self getUserInfo];
    [self getFriends];
}

/*
 * Method will be called if login faild (cancelled == YES if user cancelled login, NO otherwise)
 * Метод будет вызван, если при авторизации произошла ошибка (cancelled == YES если пользователь прервал авторизацию, NO во всех остальных случаях)
*/
- (void)okDidNotLogin:(BOOL)canceled {

}

/*
 * Method will be called if login faild and server returned an error
 * Метод будет вызван, если сервер вернул ошибку авторизации
*/
- (void)okDidNotLoginWithError:(NSError *)error {

}

/*
 * Method will be called if [_api refreshToken] called and new access_token was got
 * Метод будет вызван в случае, если вызван [_api refreshToken] и получен новый access_token
*/
- (void)okDidExtendToken:(NSString *)accessToken {
	[self okDidLogin];
}

/*
 * Method will be called if [_api refreshToken] called and new access_token wasn't got
 * Метод будет вызван в случае, если вызван [_api refreshToken] и новый access_token не получен
*/
- (void)okDidNotExtendToken:(NSError *)error {

}

/*
 * Method will be called after logout ([_api logout])
 * Метод будет вызван после выхода пользователя ([_api logout])
*/
- (void)okDidLogout {
    self.sessionStatusLabel.text = @"Not logged in";
    [self.authButton setTitle:@"Login" forState:UIControlStateNormal];
    [self clearUserInfo];
}

#pragma mark - table view

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.friends count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *simpleTableIdentifier = @"SimpleTableItem";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:simpleTableIdentifier];
    }

    FriendObject *friend = self.friends[(NSUInteger) indexPath.row];

    cell.textLabel.text = friend.fullName;
    cell.detailTextLabel.text = friend.isOnline ? @"online" : @"offline";

//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//        NSURL *url = [NSURL URLWithString:((FriendObject *)[friends objectAtIndex:indexPath.row]).pic_1Url];
//        NSData *data = [NSData dataWithContentsOfURL:url];
//        UIImage *img = [[UIImage alloc] initWithData:data];
//        dispatch_sync(dispatch_get_main_queue(), ^{
//            cell.imageView.image = img;
//            [cell setNeedsLayout];
//        });
//    });
    return cell;
}

#pragma mark - interface

- (void)loginButtonClick:(id)sender {
    if (!self.api.isSessionValid) {
        [self.api authorizeWithPermissions:@[@"VALUABLE ACCESS"]];
    } else {
        [self.api logout];
    }
}

- (void)clearUserInfo {
    self.nameTextField.text = @"";
    self.surnameTextField.text = @"";
    self.countryTextField.text = @"";

    self.photo.image = [UIImage imageNamed:@"q.png"];
    self.friends = nil;
    [self.tableView reloadData];
}

@end