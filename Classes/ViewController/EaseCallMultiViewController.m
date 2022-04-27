//
//  EaseCallMultiViewController.m
//  EMiOSDemo
//
//  Created by lixiaoming on 2020/11/19.
//  Copyright © 2020 lixiaoming. All rights reserved.
//

#import "EaseCallMultiViewController.h"
#import "EaseCallStreamView.h"
#import "EaseCallManager+Private.h"
#import <Masonry/Masonry.h>
#import <SDWebImage/UIImageView+WebCache.h>
#import "UIImage+Ext.h"
#import "EaseCallLocalizable.h"
#import "EaseCallStreamViewModel.h"
#import "EaseCallMultiViewLayout.h"

@interface EaseCallMultiViewController () <EaseCallStreamViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate>

@property (nonatomic) UIButton *inviteButton;
@property (nonatomic) BOOL isJoined;
@property (nonatomic) EaseCallStreamView *miniView;
@property (nonatomic, strong) UICollectionView *collectionView;

@property (nonatomic, strong) NSMutableArray<EaseCallStreamViewModel *> *allUserList;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, EaseCallStreamViewModel *> *joinedUserDictionary;
@property (nonatomic, strong) NSMutableDictionary<NSString *, EaseCallStreamViewModel *> *unjoinedUserDictionary;

@property (nonatomic, strong) dispatch_source_t timer;
@property (nonatomic, strong) NSMutableDictionary <NSNumber *, NSNumber *>*isTalkingDictionary;

@end

@implementation EaseCallMultiViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    _allUserList = [NSMutableArray array];
    _joinedUserDictionary = [NSMutableDictionary dictionary];
    _unjoinedUserDictionary = [NSMutableDictionary dictionary];
    _isTalkingDictionary = [NSMutableDictionary dictionary];
    
    EaseCallStreamViewModel *model = [[EaseCallStreamViewModel alloc] init];
    model.uid = 0;
    model.enableVideo = self.callType == EaseCallTypeMulti;
    model.callType = self.callType;
    model.isMini = NO;
    model.joined = self.inviterId.length <= 0;
    model.showUsername = AgoraChatClient.sharedClient.currentUsername;
    model.showUserHeaderURL = [EaseCallManager.sharedManager getHeadImageByUserName:AgoraChatClient.sharedClient.currentUsername];
    [_allUserList addObject:model];
    _joinedUserDictionary[@(0)] = model;
    
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

- (void)setCallType:(EaseCallType)callType {
    [super setCallType:callType];
}

- (void)setupSubViews
{
    self.contentView.backgroundColor = [UIColor colorWithRed:40.0 / 255 green:40.0 / 255 blue:45.0 / 255 alpha:1];
    self.inviteButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.inviteButton setImage:[UIImage agoraChatCallKit_imageNamed:@"invite"] forState:UIControlStateNormal];
    [self.inviteButton addTarget:self action:@selector(inviteAction) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:self.inviteButton];
    [self.inviteButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.miniButton);
        make.right.equalTo(@-18);
        make.width.height.equalTo(@50);
    }];
    [self.contentView bringSubviewToFront:self.inviteButton];
    [self.inviteButton setHidden:YES];
    
    [self.switchCameraButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.miniButton);
        make.width.height.equalTo(@40);
        make.right.equalTo(self.inviteButton.mas_left).offset(-16);
    }];
    
    __weak typeof(self)weakSelf = self;
    EaseCallMultiViewLayout *layout = [[EaseCallMultiViewLayout alloc] init];
    layout.isVideo = self.callType == EaseCallTypeMulti;
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
    [_collectionView registerClass:EaseCallStreamView.class forCellWithReuseIdentifier:@"cell"];
    [self.contentView addSubview:_collectionView];
    [_collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.centerX.equalTo(self.contentView);
        make.top.equalTo(self.callType == EaseCallTypeMulti ? @0 : @97);
        make.bottom.equalTo(self.buttonView.mas_top);
    }];
    
    if (self.inviterId.length > 0) {
        NSURL *remoteUrl = [EaseCallManager.sharedManager getHeadImageByUserName:self.inviterId];
        EaseCallStreamViewModel *localModel = _allUserList.firstObject;
        localModel.showUserHeaderURL = remoteUrl;
        localModel.showUsername = [EaseCallManager.sharedManager getNicknameByUserName:self.inviterId];
        if (self.callType == EaseCallTypeMulti) {
            localModel.showStatusText = EaseCallLocalizableString(@"MultiVidioCall",nil);
        } else {
            localModel.showStatusText = EaseCallLocalizableString(@"MultiAudioCall",nil);
        }
    } else {
        self.isJoined = YES;
        self.inviteButton.hidden = NO;
    }
    
    [self.contentView bringSubviewToFront:self.miniButton];
}

- (void)addMember:(NSNumber *)uId enableVideo:(BOOL)aEnableVideo
{
    if (_joinedUserDictionary[uId]) {
        return;
    }
    BOOL isNew = NO;
    EaseCallStreamViewModel *model = _unjoinedUserDictionary[uId];
    if (!model) {
        model = [[EaseCallStreamViewModel alloc] init];
        model.callType = self.callType;
        model.uid = uId.integerValue;
        model.isMini = NO;
        model.isTalking = NO;
        model.enableVoice = YES;
        isNew = YES;
    }
    model.enableVideo = aEnableVideo;
    model.joined = YES;
    
    if (isNew) {
        [_allUserList addObject:model];
    }
    _joinedUserDictionary[uId] = model;

    [_collectionView reloadData];
    
    [self startTimer];
}

- (void)setRemoteViewNickname:(NSString *)nickname headImage:(NSURL *)url uId:(NSNumber *)uid
{
    EaseCallStreamViewModel *model = _joinedUserDictionary[uid];
    if (model) {
        model.showUsername = nickname;
        model.showUserHeaderURL = url;
        [[self streamViewWithUid:uid.integerValue] update];
    }
}

- (void)removeRemoteViewForUser:(NSNumber *)uId
{
    EaseCallStreamViewModel *model = _joinedUserDictionary[uId];
    if (model) {
        [_allUserList removeObject:model];
        [_joinedUserDictionary removeObjectForKey:uId];
        [_collectionView reloadData];
    }
}

- (void)setRemoteMute:(BOOL)muted uid:(NSNumber*)uId
{
    EaseCallStreamViewModel *model = _joinedUserDictionary[uId];
    if (model) {
        model.enableVoice = !muted;
        [[self streamViewWithUid:uId.integerValue] update];
    }
}

- (void)setRemoteEnableVideo:(BOOL)aEnabled uId:(NSNumber*)uId
{
    EaseCallStreamViewModel *model = _joinedUserDictionary[uId];
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

- (EaseCallStreamView *)localView
{
    for (EaseCallStreamView *view in _collectionView.visibleCells) {
        if (view.model.uid == 0) {
            return view;
        }
    }
    return nil;
}

- (EaseCallStreamView *)streamViewWithUid:(NSInteger)uid
{
    for (EaseCallStreamView *view in _collectionView.visibleCells) {
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
        if (self.callType == EaseCallTypeMulti) {
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
    if (self.callType == EaseCallTypeMulti) {
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
    [EaseCallManager.sharedManager inviteAction];
}

- (void)answerAction
{
    [super answerAction];
    self.isJoined = YES;
    _allUserList.firstObject.joined = YES;
    [self _refreshViewPos];
}

- (void)muteAction
{
    [super muteAction];
    _allUserList[0].enableVoice = !self.microphoneButton.isSelected;
    EaseCallStreamView *localView = self.localView;
    if (localView) {
        [localView update];
        if (_allUserList[0].enableVoice) {
            [EaseCallManager.sharedManager muteAudio:NO];
        } else {
            [EaseCallManager.sharedManager muteAudio:YES];
        }
    }
}

- (void)enableVideoAction
{
    [super enableVideoAction];
    _allUserList[0].enableVideo = !self.enableCameraButton.isSelected;
    self.switchCameraButton.hidden = self.enableCameraButton.isSelected;
    if (_allUserList.count == 2) {
        [_collectionView reloadData];
    } else {
        EaseCallStreamView *cell = self.localView;
        if (cell) {
            [cell update];
            if (_allUserList[0].enableVideo) {
                [EaseCallManager.sharedManager setupLocalVideo:cell.displayView];
            } else {
                [EaseCallManager.sharedManager setupLocalVideo:nil];
            }
        }
    }
}

- (void)setPlaceHolderUrl:(NSURL*)url member:(NSString *)userName
{
    EaseCallStreamViewModel *model = _unjoinedUserDictionary[userName];
    if (!model) {
        model = [[EaseCallStreamViewModel alloc] init];
        model.uid = -1;
        model.showUsername = [EaseCallManager.sharedManager getNicknameByUserName:userName];
        model.showUserHeaderURL = url;
        model.callType = self.callType;
        model.joined = NO;
        
        [_allUserList addObject:model];
        _unjoinedUserDictionary[userName] = model;
        [_collectionView reloadData];
    }
}

- (void)removePlaceHolderForMember:(NSString *)userName
{
    EaseCallStreamViewModel *model = _unjoinedUserDictionary[userName];
    if (model) {
        if (model.uid == -1) {
            [_allUserList removeObject:model];
        }
        [_unjoinedUserDictionary removeObjectForKey:userName];
        [_collectionView reloadData];
    }
}

- (void)setUser:(NSInteger)userId isTalking:(BOOL)isTalking
{
    dispatch_async(dispatch_get_main_queue(), ^{
        EaseCallStreamViewModel *model = _joinedUserDictionary[@(userId)];
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
    for (EaseCallStreamViewModel *model in _allUserList) {
        [userIds addObject:@(model.uid)];
    }
    return userIds;
}

- (void)miniAction
{
    if (((EaseCallMultiViewLayout *)_collectionView.collectionViewLayout).bigIndex != -1) {
        ((EaseCallMultiViewLayout *)_collectionView.collectionViewLayout).bigIndex = -1;
        [_collectionView reloadData];
        [self.miniButton setImage:[UIImage agoraChatCallKit_imageNamed:@"mini"] forState:UIControlStateNormal];
        return;
    }
    self.isMini = YES;

    if (!_miniView) {
        _miniView = [[EaseCallStreamView alloc] init];
        _miniView.model = [[EaseCallStreamViewModel alloc] init];
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
        if (self.callType == EaseCallTypeMulti) {
            _miniView.model.showUsername = EaseCallLocalizableString(@"VideoCall",nil);
        } else {
            _miniView.model.showUsername = EaseCallLocalizableString(@"AudioCall",nil);
        }
    }
    [_miniView update];
    
    UIWindow *keyWindow = UIApplication.sharedApplication.keyWindow;
    if (!_miniView.superview) {
        [keyWindow addSubview:_miniView];
    }
    [self updatePositionToMiniView];
    _miniView.hidden = NO;
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)updateMiniViewPosition
{
    EaseCallMiniViewPosition position;
    position.isLeft = _miniView.center.x <= self.contentView.bounds.size.width / 2;
    position.top = _miniView.frame.origin.y;
    self.miniViewPosition = position;
}

- (void)updatePositionToMiniView
{
    CGFloat x = 20;
    if (!self.miniViewPosition.isLeft) {
        x = self.contentView.bounds.size.width - 96;
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
        for (EaseCallStreamViewModel *model in _allUserList) {
            NSString *username = [EaseCallManager.sharedManager getUserNameByUid:@(model.uid)];
            model.showUsername = username;
        }
        for (EaseCallStreamView *cell in _collectionView.visibleCells) {
            [cell update];
        }
    });
}

- (void)setupLocalVideo
{
    [EaseCallManager.sharedManager setupLocalVideo:self.localView.displayView];
}

- (void)setupRemoteVideoView:(NSUInteger)uid
{
    [EaseCallManager.sharedManager setupRemoteVideoView:uid withDisplayView:[self streamViewWithUid:uid].displayView];
}

- (void)dealloc
{
    [_miniView removeFromSuperview];
}

#pragma mark - EaseCallStreamViewDelegate
- (void)streamViewDidTap:(EaseCallStreamView *)aVideoView
{
    if (self.isMini) {
        self.isMini = NO;
        _miniView.hidden = YES;
        UIViewController *rootViewController = UIApplication.sharedApplication.keyWindow.rootViewController;
        [rootViewController presentViewController:self animated:YES completion:nil];
        return;
    }
    
    if (self.callType != EaseCallTypeMulti) {
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
        ((EaseCallMultiViewLayout *)self.collectionView.collectionViewLayout).bigIndex = bigIndex;
        [_collectionView reloadData];
        [self.miniButton setImage:[UIImage agoraChatCallKit_imageNamed:@"big_mini"] forState:UIControlStateNormal];
    }
}

- (void)streamView:(EaseCallStreamView *)videoView didPan:(UIPanGestureRecognizer *)panGesture
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
    return _allUserList.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    EaseCallStreamViewModel *model = _allUserList[indexPath.item];
    EaseCallStreamView *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    model.isMini = NO;
    if (self.callType == EaseCallTypeMulti) {
        if (model.uid == 0) {
            [EaseCallManager.sharedManager setupLocalVideo:cell.displayView];
            model.isMini = _allUserList.count == 2 && ((EaseCallMultiViewLayout *)collectionView.collectionViewLayout).bigIndex == -1;
        } else {
            [EaseCallManager.sharedManager muteRemoteVideoStream:model.uid mute:NO];
            [EaseCallManager.sharedManager setupRemoteVideoView:model.uid withDisplayView:cell.displayView];
        }
    }
    cell.delegate = self;
    cell.model = model;
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.callType != EaseCallTypeMulti) {
        return;
    }
    if (indexPath.item >= _allUserList.count) {
        return;
    }
    
    for (NSIndexPath *index in collectionView.indexPathsForVisibleItems) {
        if (indexPath.section == index.section && indexPath.item == index.item) {
            return;
        }
    }
    
    EaseCallStreamViewModel *model = _allUserList[indexPath.item];
    
    if (model.uid != 0) {
        [EaseCallManager.sharedManager muteRemoteVideoStream:model.uid mute:YES];
    }
}

@end
