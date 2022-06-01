//
//  EaseCallMultiViewController.m
//  EMiOSDemo
//
//  Created by lixiaoming on 2020/11/19.
//  Copyright © 2020 lixiaoming. All rights reserved.
//

#import "AgoraChatCallMultiViewController.h"
#import "AgoraChatCallStreamView.h"
#import "AgoraChatCallManager+Private.h"
#import <Masonry/Masonry.h>
#import <SDWebImage/UIImageView+WebCache.h>
#import "UIImage+Ext.h"
#import "AgoraChatCallLocalizable.h"
#import "AgoraChatCallStreamViewModel.h"
#import "AgoraChatCallMultiViewLayout.h"

@interface AgoraChatCallMultiViewController () <AgoraChatCallStreamViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate>

@property (nonatomic) UIButton *inviteButton;
@property (nonatomic) BOOL isJoined;
@property (nonatomic) AgoraChatCallStreamView *miniView;
@property (nonatomic, strong) UICollectionView *collectionView;

@property (nonatomic, strong) NSMutableArray<AgoraChatCallStreamViewModel *> *allUserList;
@property (nonatomic, strong) NSMutableArray<AgoraChatCallStreamViewModel *> *showUserList;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, AgoraChatCallStreamViewModel *> *joinedUserDictionary;
@property (nonatomic, strong) NSMutableDictionary<NSString *, AgoraChatCallStreamViewModel *> *unjoinedUserDictionary;

@property (nonatomic, strong) dispatch_source_t timer;
@property (nonatomic, strong) NSMutableDictionary <NSNumber *, NSNumber *>*isTalkingDictionary;

@end

@implementation AgoraChatCallMultiViewController

- (instancetype)init
{
    if (self = [super init]) {
        _allUserList = [NSMutableArray array];
        _showUserList = [NSMutableArray array];
        _joinedUserDictionary = [NSMutableDictionary dictionary];
        _unjoinedUserDictionary = [NSMutableDictionary dictionary];
        _isTalkingDictionary = [NSMutableDictionary dictionary];
        
        AgoraChatCallStreamViewModel *model = [[AgoraChatCallStreamViewModel alloc] init];
        model.uid = 0;
        model.agoraUsername = AgoraChatClient.sharedClient.currentUsername;
        model.enableVideo = self.callType == AgoraChatCallTypeMultiVideo;
        model.callType = self.callType;
        model.isMini = NO;
        model.joined = self.inviterId.length <= 0;
        model.showUsername = [AgoraChatCallManager.sharedManager getNicknameByUserName:model.agoraUsername];
        model.showUserHeaderURL = [AgoraChatCallManager.sharedManager getHeadImageByUserName:model.agoraUsername];
        [_allUserList addObject:model];
        [_showUserList addObject:model];
        _joinedUserDictionary[@(0)] = model;
    }
    return self;
}

- (void)setCallType:(AgoraChatCallType)callType
{
    [super setCallType:callType];
    
    for (AgoraChatCallStreamViewModel *model in _allUserList) {
        model.callType = callType;
    }
    [_collectionView reloadData];
    if (callType == AgoraChatCallTypeMultiVideo) {
        _allUserList[0].enableVideo = !self.enableCameraButton.isSelected;
        if (_allUserList[0].enableVideo) {
            [AgoraChatCallManager.sharedManager startPreview];
        }
        for (AgoraChatCallStreamView *view in _collectionView.visibleCells) {
            [view update];
        }
        [AgoraChatCallManager.sharedManager muteLocalVideoStream:self.enableCameraButton.selected];
    } else {
        [AgoraChatCallManager.sharedManager muteLocalVideoStream:YES];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    __weak typeof(self)weakSelf = self;
    _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
    dispatch_source_set_timer(_timer, DISPATCH_TIME_NOW, 0.1, 0);
    dispatch_source_set_event_handler(_timer, ^{
        CFAbsoluteTime now = CFAbsoluteTimeGetCurrent();
        [weakSelf.isTalkingDictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull key, NSNumber * _Nonnull obj, BOOL * _Nonnull stop) {
            if (now - obj.doubleValue >= 0.3 || now < obj.doubleValue) {
                [weakSelf setUser:key isTalking:NO];
                [weakSelf.isTalkingDictionary removeObjectForKey:key];
            }
        }];
    });
    dispatch_resume(_timer);
    
    [self setupSubViews];
    [self _refreshViewPos];
}

- (void)setupSubViews
{
    self.contentView.backgroundColor = [UIColor colorWithRed:40.0 / 255 green:40.0 / 255 blue:45.0 / 255 alpha:1];
    self.inviteButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.inviteButton setImage:[UIImage agoraChatCallKit_imageNamed:@"invite"] forState:UIControlStateNormal];
    [self.inviteButton addTarget:self action:@selector(inviteAction) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:self.inviteButton];
    
    [self.contentView bringSubviewToFront:self.inviteButton];
    
    __weak typeof(self)weakSelf = self;
    AgoraChatCallMultiViewLayout *layout = [[AgoraChatCallMultiViewLayout alloc] init];
    layout.isVideo = self.callType == AgoraChatCallTypeMultiVideo;
    layout.getVideoEnableBlock = ^BOOL(NSIndexPath * _Nonnull indexPath) {
        if (weakSelf.allUserList.count <= indexPath.item) {
            return YES;
        }
        return weakSelf.allUserList[indexPath.item].enableVideo;
    };
    _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    _collectionView.dataSource = self;
    _collectionView.delegate = self;
    _collectionView.backgroundColor = UIColor.clearColor;
    [_collectionView registerClass:AgoraChatCallStreamView.class forCellWithReuseIdentifier:@"cell"];
    [self.contentView insertSubview:_collectionView atIndex:0];
    [_collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.centerX.equalTo(self.contentView);
        make.top.equalTo(self.callType == AgoraChatCallTypeMultiVideo ? @0 : @97);
        make.bottom.equalTo(self.buttonView.mas_top);
    }];
    
    if (self.inviterId.length > 0) {
        NSURL *remoteUrl = [AgoraChatCallManager.sharedManager getHeadImageByUserName:self.inviterId];
        AgoraChatCallStreamViewModel *localModel = _allUserList.firstObject;
        localModel.showUserHeaderURL = remoteUrl;
        localModel.showUsername = [AgoraChatCallManager.sharedManager getNicknameByUserName:self.inviterId];
        if (self.callType == AgoraChatCallTypeMultiVideo) {
            localModel.showStatusText = AgoraChatCallLocalizableString(@"MultiVidioCall",nil);
        } else {
            localModel.showStatusText = AgoraChatCallLocalizableString(@"MultiAudioCall",nil);
        }
    } else {
        self.isJoined = YES;
        [self startTimer];
    }
    
    [self.inviteButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.miniButton);
        make.right.equalTo(@-18);
        make.width.height.equalTo(@50);
    }];
    
    [self.switchCameraButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.miniButton);
        make.width.height.equalTo(@40);
        make.right.equalTo(self.inviteButton.mas_left).offset(-16);
    }];
    
    [self.contentView bringSubviewToFront:self.miniButton];
}

- (void)addMember:(NSNumber *)uId username:(NSString *)username enableVideo:(BOOL)aEnableVideo
{
    if (_joinedUserDictionary[uId]) {
        return;
    }
    BOOL isNew = NO;
    AgoraChatCallStreamViewModel *model = _unjoinedUserDictionary[username];
    if (!model) {
        model = [[AgoraChatCallStreamViewModel alloc] init];
        model.callType = self.callType;
        model.isMini = NO;
        model.isTalking = NO;
        model.enableVoice = YES;
        isNew = YES;
    }
    model.showUsername = username;
    model.showUserHeaderURL = [AgoraChatCallManager.sharedManager getNicknameByUserName:username];
    model.showUserHeaderURL = [AgoraChatCallManager.sharedManager getHeadImageByUserName:username];
    model.uid = uId.integerValue;
    model.enableVideo = aEnableVideo;
    model.joined = YES;
    
    if (isNew) {
        [_allUserList addObject:model];
        [self updateShowUserList];
    }
    _joinedUserDictionary[uId] = model;

    [_collectionView reloadData];
}

- (void)updateShowUserList
{
    [_showUserList removeAllObjects];
    for (AgoraChatCallStreamViewModel *model in _allUserList) {
        if (model.showUsername.length > 0) {
            [_showUserList addObject:model];
        }
    }
}

- (void)removeRemoteViewForUser:(NSNumber *)uId
{
    AgoraChatCallStreamViewModel *model = _joinedUserDictionary[uId];
    if (model) {
        [_allUserList removeObject:model];
        [self updateShowUserList];
        [_joinedUserDictionary removeObjectForKey:uId];
        [_collectionView reloadData];
    }
}

- (void)setRemoteMute:(BOOL)muted uid:(NSNumber*)uId
{
    AgoraChatCallStreamViewModel *model = _joinedUserDictionary[uId];
    if (model) {
        model.enableVoice = !muted;
        [[self streamViewWithUid:uId.integerValue] update];
    }
}

- (void)setRemoteEnableVideo:(BOOL)aEnabled uId:(NSNumber*)uId
{
    AgoraChatCallStreamViewModel *model = _joinedUserDictionary[uId];
    if (model) {
        model.enableVideo = aEnabled;
        for (NSIndexPath *indexPath in _collectionView.indexPathsForVisibleItems) {
            if (_allUserList[indexPath.item] == model) {
                [_collectionView reloadItemsAtIndexPaths:@[indexPath]];
                return;
            }
        }
    }
}

- (AgoraChatCallStreamView *)localView
{
    for (AgoraChatCallStreamView *view in _collectionView.visibleCells) {
        if (view.model.uid == 0) {
            return view;
        }
    }
    return nil;
}

- (AgoraChatCallStreamView *)streamViewWithUid:(NSInteger)uid
{
    for (AgoraChatCallStreamView *view in _collectionView.visibleCells) {
        if (view.model.uid == uid) {
            return view;
        }
    }
    return nil;
}

- (void)_refreshViewPos
{
    self.microphoneButton.hidden = !self.isJoined;
    
    if (!self.isJoined) {
        if (self.callType == AgoraChatCallTypeMultiVideo) {
            self.speakerButton.hidden = YES;
            self.switchCameraButton.hidden = YES;
            self.enableCameraButton.hidden = NO;
            [self.enableCameraButton mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.bottom.equalTo(self.buttonView);
                make.left.equalTo(@40);
                make.width.height.equalTo(@100);
            }];
        } else {
            self.speakerButton.hidden = NO;
            self.switchCameraButton.hidden = YES;
            self.enableCameraButton.hidden = YES;
            [self.speakerButton mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.bottom.equalTo(self.buttonView);
                make.left.equalTo(@40);
                make.width.height.equalTo(@100);
            }];
        }
        [self.hangupButton mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.bottom.equalTo(self.buttonView);
            make.centerX.equalTo(self.buttonView);
            make.width.height.equalTo(@100);
        }];
        [self.answerButton mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.bottom.equalTo(self.buttonView);
            make.right.equalTo(@-40);
            make.width.height.equalTo(@100);
        }];
        return;
    }

    self.answerButton.hidden = YES;
    if (self.callType == AgoraChatCallTypeMultiVideo) {
        self.enableCameraButton.hidden = NO;
        self.speakerButton.hidden = YES;
        self.switchCameraButton.hidden = NO;
        [self.enableCameraButton mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.bottom.equalTo(self.buttonView);
            make.left.equalTo(@40);
            make.width.height.equalTo(@100);
        }];
    } else {
        self.switchCameraButton.hidden = YES;
        self.enableCameraButton.hidden = YES;
        self.speakerButton.hidden = NO;
        [self.speakerButton mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.bottom.equalTo(self.buttonView);
            make.left.equalTo(@40);
            make.width.height.equalTo(@100);
        }];
    }
    
    [self.microphoneButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.buttonView);
        make.centerX.equalTo(self.buttonView);
        make.width.height.equalTo(@100);
    }];
    
    [self.hangupButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.buttonView);
        make.right.equalTo(@-40);
        make.width.height.equalTo(@100);
    }];
}

- (void)inviteAction
{
    [AgoraChatCallManager.sharedManager inviteAction];
}

- (void)answerAction
{
    [super answerAction];
    self.isJoined = YES;
    _allUserList.firstObject.joined = YES;
    [self _refreshViewPos];
    [self startTimer];
}

- (void)didMuteAudio:(BOOL)mute
{
    [super didMuteAudio:mute];
    _allUserList[0].enableVoice = !mute;
    AgoraChatCallStreamView *localView = self.localView;
    if (localView) {
        [localView update];
    }
}

- (void)enableVideoAction
{
    [super enableVideoAction];
//    return;
    _allUserList[0].enableVideo = !self.enableCameraButton.isSelected;
    self.switchCameraButton.hidden = self.enableCameraButton.isSelected;
    if (_allUserList.count == 2) {
        [_collectionView reloadData];
    } else {
        AgoraChatCallStreamView *cell = self.localView;
        if (cell) {
            [cell update];
            if (_allUserList[0].enableVideo) {
                [AgoraChatCallManager.sharedManager setupLocalVideo:cell.displayView];
            } else {
                [AgoraChatCallManager.sharedManager setupLocalVideo:nil];
            }
        }
    }
}

- (void)setPlaceHolderUrl:(NSURL*)url member:(NSString *)userName
{
    AgoraChatCallStreamViewModel *model = _unjoinedUserDictionary[userName];
    if (!model) {
        model = [[AgoraChatCallStreamViewModel alloc] init];
        model.uid = -1;
        model.showUsername = [AgoraChatCallManager.sharedManager getNicknameByUserName:userName];
        model.showUserHeaderURL = url;
        model.callType = self.callType;
        model.joined = NO;
        
        [_allUserList addObject:model];
        [self updateShowUserList];
        _unjoinedUserDictionary[userName] = model;
        [_collectionView reloadData];
    }
}

- (void)removePlaceHolderForMember:(NSString *)userName
{
    AgoraChatCallStreamViewModel *model = _unjoinedUserDictionary[userName];
    if (model) {
        if (model.uid == -1) {
            [_allUserList removeObject:model];
            [self updateShowUserList];
        }
        [_unjoinedUserDictionary removeObjectForKey:userName];
        [_collectionView reloadData];
    }
}

- (void)setUser:(NSInteger)userId isTalking:(BOOL)isTalking
{
    dispatch_async(dispatch_get_main_queue(), ^{
        AgoraChatCallStreamViewModel *model = _joinedUserDictionary[@(userId)];
        if (!model) {
            return;
        }
        if (isTalking) {
            _isTalkingDictionary[@(userId)] = @(CFAbsoluteTimeGetCurrent());
        }
        if (model.isTalking != isTalking) {
            model.isTalking = isTalking;
            [[self streamViewWithUid:userId] update];
        }
    });
}

- (NSArray<NSNumber *> *)getAllUserIds {
    NSMutableArray<NSNumber *> *userIds = [NSMutableArray array];
    for (NSNumber *uid in _joinedUserDictionary) {
        [userIds addObject:uid];
    }
    return userIds;
}

- (void)miniAction
{
    AgoraChatCallMultiViewLayout *layout = _collectionView.collectionViewLayout;
    if (layout && layout.bigIndex != -1) {
        layout.bigIndex = -1;
        [_collectionView reloadData];
        [self.miniButton setImage:[UIImage agoraChatCallKit_imageNamed:@"mini"] forState:UIControlStateNormal];
        return;
    }
    self.isMini = YES;

    if (!_miniView) {
        _miniView = [[AgoraChatCallStreamView alloc] init];
        _miniView.model = [[AgoraChatCallStreamViewModel alloc] init];
        _miniView.model.isMini = YES;
        _miniView.model.enableVideo = NO;
        _miniView.model.callType = self.callType;
        _miniView.delegate = self;
        _miniView.panGestureActionEnable = YES;
    }
    if (self.isJoined) {
        int timeLength = self.timeLength;
        int m = timeLength / 60;
        int s = timeLength - m * 60;
        _miniView.model.showUsername = [NSString stringWithFormat:@"%02d:%02d", m, s];
    } else {
        if (self.callType == AgoraChatCallTypeMultiVideo) {
            _miniView.model.showUsername = AgoraChatCallLocalizableString(@"VideoCall",nil);
        } else {
            _miniView.model.showUsername = AgoraChatCallLocalizableString(@"AudioCall",nil);
        }
    }
    [_miniView update];
    
    UIWindow *keyWindow = [AgoraChatCallManager.sharedManager getKeyWindow];
    if (!_miniView.superview) {
        [keyWindow addSubview:_miniView];
    }
    [self updatePositionToMiniView];
    _miniView.hidden = NO;
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)updateMiniViewPosition
{
    AgoraChatCallMiniViewPosition position;
    UIWindow *keyWindow = [AgoraChatCallManager.sharedManager getKeyWindow];
    position.isLeft = _miniView.center.x <= keyWindow.bounds.size.width / 2;
    position.top = _miniView.frame.origin.y;
    self.miniViewPosition = position;
}

- (void)updatePositionToMiniView
{
    CGFloat x = 20;
    if (!self.miniViewPosition.isLeft) {
        UIWindow *keyWindow = [AgoraChatCallManager.sharedManager getKeyWindow];
        x = keyWindow.bounds.size.width - 96;
    }
    _miniView.frame = CGRectMake(x, self.miniViewPosition.top, 76, 76);
}

- (void)callTimerDidChange:(NSUInteger)min sec:(NSUInteger)sec
{
    if (self.isJoined && self.isMini) {
        _miniView.model.showUsername = [NSString stringWithFormat:@"%02d:%02d", min, sec];
        [_miniView update];
    }
}

- (void)usersInfoUpdated
{
    dispatch_async(dispatch_get_main_queue(), ^{
        BOOL needRefresh = NO;
        NSMutableArray *removeList = [NSMutableArray array];
        for (AgoraChatCallStreamViewModel *model in _allUserList) {
            NSString *username = [AgoraChatCallManager.sharedManager getUserNameByUid:@(model.uid)];
            if (username) {
                AgoraChatCallStreamViewModel *unjoinedModel = _unjoinedUserDictionary[username];
                if (unjoinedModel && _joinedUserDictionary[@(model.uid)]) {
                    [_unjoinedUserDictionary removeObjectForKey:username];
                    [removeList addObject:unjoinedModel];
                }
                if (model.agoraUsername.length <= 0) {
                    needRefresh = YES;
                }
                model.agoraUsername = username;
                model.showUsername = [AgoraChatCallManager.sharedManager getNicknameByUserName:username];
                model.showUserHeaderURL = [AgoraChatCallManager.sharedManager getHeadImageByUserName:username];
            }
        }
        [_allUserList removeObjectsInArray:removeList];
        if (needRefresh) {
            [self updateShowUserList];
            [self.collectionView reloadData];
        } else {
            for (AgoraChatCallStreamView *cell in _collectionView.visibleCells) {
                [cell update];
            }
        }
    });
}

- (void)setupLocalVideo
{
    [AgoraChatCallManager.sharedManager setupLocalVideo:self.localView.displayView];
}

- (void)setupRemoteVideoView:(NSUInteger)uid size:(CGSize)size
{
    [AgoraChatCallManager.sharedManager setupRemoteVideoView:uid withDisplayView:[self streamViewWithUid:uid].displayView];
}

- (void)dealloc
{
    [_miniView removeFromSuperview];
}

#pragma mark - EaseCallStreamViewDelegate
- (void)streamViewDidTap:(AgoraChatCallStreamView *)aVideoView
{
    if (self.isMini) {
        self.isMini = NO;
        _miniView.hidden = YES;
        UIViewController *rootViewController = [AgoraChatCallManager.sharedManager getKeyWindow].rootViewController;
        [rootViewController presentViewController:self animated:YES completion:nil];
        return;
    }
    
    if (self.callType != AgoraChatCallTypeMultiVideo) {
        return;
    }
    
    NSInteger bigIndex = -1;
    for (int i = 0; i < _allUserList.count; i ++) {
        if (_allUserList[i] == aVideoView.model) {
            bigIndex = i;
            break;
        }
    }
    if (bigIndex != -1) {
        ((AgoraChatCallMultiViewLayout *)self.collectionView.collectionViewLayout).bigIndex = bigIndex;
        [_collectionView reloadData];
        [self.miniButton setImage:[UIImage agoraChatCallKit_imageNamed:@"big_mini"] forState:UIControlStateNormal];
    }
}

- (void)streamView:(AgoraChatCallStreamView *)videoView didPan:(UIPanGestureRecognizer *)panGesture
{
    CGPoint translation = [panGesture translationInView:panGesture.view];
    CGFloat x = 20;
    if (!self.miniViewPosition.isLeft) {
        x = self.contentView.bounds.size.width - videoView.bounds.size.width - 20;
    }
    CGFloat y = self.miniViewPosition.top;
    videoView.frame = CGRectMake(x + translation.x, y + translation.y, videoView.bounds.size.width, videoView.bounds.size.height);
    if (panGesture.state == UIGestureRecognizerStateEnded || panGesture.state == UIGestureRecognizerStateCancelled) {
        [self updateMiniViewPosition];
        [UIView animateWithDuration:0.25 animations:^{
            [self updatePositionToMiniView];
        }];
    }
}

#pragma mark - UICollectionViewDataSource UICollectionViewDelegate
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _showUserList.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    AgoraChatCallStreamViewModel *model = _showUserList[indexPath.item];
    AgoraChatCallStreamView *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    model.isMini = NO;
    if (self.callType == AgoraChatCallTypeMultiVideo) {
        if (model.uid == 0) {
            model.isMini = _showUserList.count == 2 && ((AgoraChatCallMultiViewLayout *)collectionView.collectionViewLayout).bigIndex == -1;
        }
    }
    cell.delegate = self;
    cell.model = model;
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.callType != AgoraChatCallTypeMultiVideo) {
        return;
    }
    if (indexPath.item >= _showUserList.count) {
        return;
    }
    
    for (NSIndexPath *index in collectionView.indexPathsForVisibleItems) {
        if (indexPath.section == index.section && indexPath.item == index.item) {
            return;
        }
    }
    
    AgoraChatCallStreamViewModel *model = _showUserList[indexPath.item];
    
    if (model.uid != 0) {
        [AgoraChatCallManager.sharedManager muteRemoteVideoStream:model.uid mute:YES];
    }
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.callType == AgoraChatCallTypeMultiVideo) {
        AgoraChatCallStreamViewModel *model = _showUserList[indexPath.item];
        if (model.uid == 0) {
            if (model.enableVideo) {
                [AgoraChatCallManager.sharedManager setupLocalVideo:((AgoraChatCallStreamView *)cell).displayView];
            }
        } else {
            [AgoraChatCallManager.sharedManager muteRemoteVideoStream:model.uid mute:NO];
            [AgoraChatCallManager.sharedManager setupRemoteVideoView:model.uid withDisplayView:((AgoraChatCallStreamView *)cell).displayView];
        }
    }
}

#pragma mark - IAgoraChatCallIncomingAlertViewShowable
- (NSString *)showAlertTitle
{
    if (self.inviterId.length > 0) {
        return [AgoraChatCallManager.sharedManager getNicknameByUserName:self.inviterId];
    } else {
        return [super showAlertTitle];
    }
}

@end
