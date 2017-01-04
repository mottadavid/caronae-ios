#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import "CaronaeAlertController.h"
#import "EditProfileViewController.h"
#import "FalaeViewController.h"
#import "MenuViewController.h"
#import "ProfileViewController.h"
#import "RiderCell.h"
#import "SHSPhoneNumberFormatter+UserConfig.h"
#import "UIImageView+crn_setImageWithURL.h"
#import "Caronae-Swift.h"

@interface ProfileViewController () <EditProfileDelegate, UICollectionViewDataSource>
@property (weak, nonatomic) IBOutlet UIBarButtonItem *editButton;
@property (weak, nonatomic) IBOutlet UIButton *signoutButton;
@property (weak, nonatomic) IBOutlet UIView *reportView;
@property (nonatomic) NSDateFormatter *joinedDateFormatter;
@property (nonatomic) NSArray<User *> *mutualFriends;
@end

@implementation ProfileViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self updateProfileFields];
}

- (BOOL)isMyProfile {
    UINavigationController *navigationVC = self.navigationController;
    if (navigationVC.viewControllers.count >= 2) {
        UIViewController *previousVC = navigationVC.viewControllers[navigationVC.viewControllers.count - 2];
        if ([previousVC isKindOfClass:[MenuViewController class]]) {
            return YES;
        }
    }
    return NO;
}

- (void)updateProfileFields {
    if ([self isMyProfile]) {
        self.title = @"Meu Perfil";
        
        if (_user.carOwner) {
            _carPlateLabel.text = _user.carPlate;
            _carModelLabel.text = _user.carModel;
            _carColorLabel.text = _user.carColor;
        }
        else {
            _carPlateLabel.text = @"-";
            _carModelLabel.text = @"-";
            _carColorLabel.text = @"-";
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [_mutualFriendsView removeFromSuperview];
            [_reportView removeFromSuperview];
        });
    }
    else {
        self.title = _user.name;
        self.navigationItem.rightBarButtonItem = nil;
        dispatch_async(dispatch_get_main_queue(), ^{
            [_carDetailsView removeFromSuperview];
            [_signoutButton removeFromSuperview];
        });
        [self updateMutualFriends];
    }
    
    if (_user.createdAt) {
        _joinedDateFormatter = [[NSDateFormatter alloc] init];
        _joinedDateFormatter.dateFormat = @"MM/yyyy";
        _joinedDateLabel.text = [self.joinedDateFormatter stringFromDate:_user.createdAt];
    }
    
    _nameLabel.text = _user.name;
    _courseLabel.text = _user.course.length > 0 ? [NSString stringWithFormat:@"%@ | %@", _user.profile, _user.course] : _user.profile;
    _numDrivesLabel.text = _user.numDrives > -1 ? [NSString stringWithFormat:@"%ld", (long)_user.numDrives] : @"-";
    _numRidesLabel.text = _user.numRides > -1 ? [NSString stringWithFormat:@"%d", _user.numRides] : @"-";
    
    if (_user.phoneNumber.length > 0) {
        SHSPhoneNumberFormatter *phoneFormatter = [[SHSPhoneNumberFormatter alloc] init];
        [phoneFormatter setDefaultOutputPattern:Caronae8PhoneNumberPattern];
        [phoneFormatter addOutputPattern:Caronae9PhoneNumberPattern forRegExp:@"[0-9]{12}\\d*$"];
        NSDictionary *result = [phoneFormatter valuesForString:_user.phoneNumber];
        NSString *formattedPhoneNumber = result[@"text"];
        [_phoneButton setTitle:formattedPhoneNumber forState:UIControlStateNormal];
    }
    else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [_phoneView removeFromSuperview];
        });
    }
    
    if (_user.profilePictureURL.length > 0) {
        [self.profileImage crn_setImageWithURL:[NSURL URLWithString:_user.profilePictureURL]];
    }
    
    [self updateRidesOfferedCount];
}

- (void)updateRidesOfferedCount {
    // TODO: add to user service
    [CaronaeAPIHTTPSessionManager.instance GET:[NSString stringWithFormat:@"/ride/getRidesHistoryCount/%ld", (long)_user.id] parameters:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {
        int numDrives = [responseObject[@"offeredCount"] intValue];
        int numRides = [responseObject[@"takenCount"] intValue];
        
        _numDrivesLabel.text = [NSString stringWithFormat:@"%d", numDrives];
        _numRidesLabel.text = [NSString stringWithFormat:@"%d", numRides];
        
        _user.numDrives = numDrives;
        _user.numRides = numRides;

        
//        if ([self isMyProfile]) {
//            [UserController sharedInstance].user = _user;
//        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"Error reading history count for user: %@", error.localizedDescription);
    }];
}

- (void)updateMutualFriends {
    // Abort if the Facebook accounts are not connected.
    if (![UserController sharedInstance].userFBToken || _user.facebookID.length == 0) {
        return;
    }
    
    [CaronaeAPIHTTPSessionManager.instance GET:[NSString stringWithFormat:@"/user/%@/mutualFriends", _user.facebookID] parameters:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {
        NSArray *mutualFriendsJSON = responseObject[@"mutual_friends"];
        int totalMutualFriends = [responseObject[@"total_count"] intValue];
        NSError *error;
        // TODO: deserialize response
        NSArray<User *> *mutualFriends = nil;
        
        if (error) {
            NSLog(@"Error parsing user from mutual friends: %@", error.localizedDescription);
        }
        
        self.mutualFriends = mutualFriends;
        [self.mutualFriendsCollectionView reloadData];

        if (totalMutualFriends > 0) {
            _mutualFriendsLabel.text = [NSString stringWithFormat:@"Amigos em comum: %d no total e %d no Caronaê", totalMutualFriends, (int)mutualFriends.count];
        }
        else {
            _mutualFriendsLabel.text = @"Amigos em comum: 0";
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"Error loading mutual friends for user: %@", error.localizedDescription);
    }];
}


#pragma mark - Edit profile methods

- (IBAction)didTapPhoneButton:(id)sender {
    NSString *phoneNumber = _user.phoneNumber;
    NSString *phoneNumberURLString = [NSString stringWithFormat:@"telprompt://%@", phoneNumber];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:phoneNumberURLString]];
}

- (void)didUpdateUser:(User *)updatedUser {
    self.user = updatedUser;
    [self updateProfileFields];
}


#pragma mark - IBActions

- (IBAction)didTapLogoutButton:(id)sender {
    CaronaeAlertController *alert = [CaronaeAlertController alertControllerWithTitle:@"Você deseja mesmo sair da sua conta?"
                                                                             message: nil
                                                                      preferredStyle:SDCAlertControllerStyleAlert];
    [alert addAction:[SDCAlertAction actionWithTitle:@"Cancelar" style:SDCAlertActionStyleCancel handler:nil]];
    [alert addAction:[SDCAlertAction actionWithTitle:@"Sair" style:SDCAlertActionStyleDestructive handler:^(SDCAlertAction *action){
        [UserService.instance signOut];
    }]];
    [alert presentWithCompletion:nil];
}


#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"EditProfile"]) {
        UINavigationController *navigationVC = segue.destinationViewController;
        EditProfileViewController *vc = (EditProfileViewController *)navigationVC.topViewController;
        vc.delegate = self;
    }
    else if ([segue.identifier isEqualToString:@"ReportUser"]) {
        FalaeViewController *vc = segue.destinationViewController;
        [vc setReport:_user];
    }
}


#pragma mark - Collection methods (Mutual friends)

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _mutualFriends.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    User *user = _mutualFriends[indexPath.row];
    
    RiderCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Friend Cell" forIndexPath:indexPath];
    
    cell.user = user;
    cell.nameLabel.text = user.firstName;
    
    if (user.profilePictureURL.length > 0) {
        [cell.photo crn_setImageWithURL:[NSURL URLWithString:user.profilePictureURL]];
    }
    
    return cell;
}

@end
