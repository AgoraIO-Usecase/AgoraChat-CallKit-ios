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

@interface EaseCallMultiViewController () <EaseCallStreamViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate>

@property (nonatomic) UIButton *inviteButton;
@property (nonatomic) UILabel *statusLable;
@property (nonatomic) BOOL isJoined;
@property (nonatomic) EaseCallStreamView *bigView;
@property (atomic) BOOL isNeedLayout;
@property (nonatomic,strong) UILabel *remoteNameLable;
@property (nonatomic,strong) UIImageView *remoteHeadView;
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
    model.joined = YES;
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
    self.contentView.backgroundColor = [UIColor colorWithRed:0.949 green:0.949 blue:0.949 alpha:1];
    self.bigView = nil;
    self.isNeedLayout = NO;
    [self.timeLabel setHidden:YES];
    self.inviteButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.inviteButton setImage:[UIImage imageNamedFromBundle:@"invite"] forState:UIControlStateNormal];
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
    
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.minimumLineSpacing = 0;
    layout.minimumInteritemSpacing = 0;
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
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
        self.remoteHeadView = [[UIImageView alloc] init];
        [self.contentView addSubview:self.remoteHeadView];
        [self.remoteHeadView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.height.equalTo(@80);
            make.centerX.equalTo(self.contentView);
            make.top.equalTo(@100);
        }];
        [self.remoteHeadView sd_setImageWithURL:remoteUrl];
        self.remoteNameLable = [[UILabel alloc] init];
        self.remoteNameLable.backgroundColor = [UIColor clearColor];
        self.remoteNameLable.textColor = [UIColor whiteColor];
        self.remoteNameLable.textAlignment = NSTextAlignmentRight;
        self.remoteNameLable.font = [UIFont systemFontOfSize:24];
        self.remoteNameLable.text = [EaseCallManager.sharedManager getNicknameByUserName:self.inviterId];
        self.timeLabel.hidden = YES;
        [self.contentView addSubview:self.remoteNameLable];
        [self.remoteNameLable mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.remoteHeadView.mas_bottom).offset(20);
            make.centerX.equalTo(self.contentView);
        }];
        self.statusLable = [[UILabel alloc] init];
        self.statusLable.backgroundColor = UIColor.clearColor;
        self.statusLable.font = [UIFont systemFontOfSize:15];
        self.statusLable.textColor = [UIColor colorWithWhite:1.0 alpha:0.5];
        self.statusLable.textAlignment = NSTextAlignmentRight;
        self.statusLable.text = EaseCallLocalizableString(@"receiveCallInviteprompt",nil);
        self.answerButton.hidden = NO;
        [self.contentView addSubview:self.statusLable];
        [self.statusLable mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.remoteNameLable.mas_bottom).offset(20);
            make.centerX.equalTo(self.contentView);
        }];
    } else {
        self.answerButton.hidden = YES;
        [self.hangupButton mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(self.buttonView);
            make.width.height.equalTo(@100);
            make.bottom.equalTo(self.buttonView);
        }];
        self.isJoined = YES;
        self.inviteButton.hidden = NO;
    }
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    int count = self.callType == EaseCallTypeMulti ? 2 : 3;
    UICollectionViewFlowLayout *layout = _collectionView.collectionViewLayout;
    layout.itemSize = CGSizeMake(floor(_collectionView.bounds.size.width / count), floor(_collectionView.bounds.size.height / count));
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
        for (EaseCallStreamView *cell in _collectionView.visibleCells) {
            if (cell.model == model) {
                [cell update];
            }
        }
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
        for (EaseCallStreamView *cell in _collectionView.visibleCells) {
            if (cell.model == model) {
                [cell update];
            }
        }
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
    // TODO:
//    if (view == self.bigView && !aEnabled) {
//        self.bigView = nil;
//    }
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
    _remoteNameLable.hidden = self.isJoined;
    _remoteHeadView.hidden = self.isJoined;
    _collectionView.hidden = !self.isJoined;
    self.timeLabel.hidden = !self.isJoined;
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
    
    [self.timeLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.contentView);
        make.centerY.equalTo(self.inviteButton);
        make.width.equalTo(@100);
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
    [self _refreshViewPos];
}

- (void)muteAction
{
    [super muteAction];
    _allUserList[0].enableVoice = !self.microphoneButton.isSelected;
    EaseCallStreamView *cell = _collectionView.visibleCells.firstObject;
    if (cell.model.uid == 0) {
        [cell update];
    }
}

- (void)enableVideoAction
{
    [super enableVideoAction];
    _allUserList[0].enableVideo = self.enableCameraButton.isSelected;
    EaseCallStreamView *cell = _collectionView.visibleCells.firstObject;
    if (cell.model.uid == 0) {
        [cell update];
        if (_allUserList[0].enableVideo) {
            [EaseCallManager.sharedManager setupLocalVideo:cell.displayView];
        } else {
            [EaseCallManager.sharedManager setupLocalVideo:nil];
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
        model.isTalking = isTalking;
        if (isTalking) {
            _isTalkingDictionary[@(userId)] = @(CFAbsoluteTimeGetCurrent());
        }
        for (EaseCallStreamView *cell in _collectionView.visibleCells) {
            if (cell.model.uid == userId) {
                [cell update];
                return;
            }
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

- (void)streamViewDidTap:(EaseCallStreamView *)aVideoView
{
    // TODO:
    if (self.isMini) {
        self.isMini = NO;
//        self.remoteView.model.isMini = YES;
//        [self.remoteView removeFromSuperview];
//        UIWindow *window = UIApplication.sharedApplication.keyWindow;
//        UIViewController *rootViewController = window.rootViewController;
//        self.modalPresentationStyle = 0;
//        [rootViewController presentViewController:self animated:YES completion:nil];
//        if (self.type == EaseCallType1v1Video) {
//            self.remoteView.model.enableVideo = YES;
//        }
//        [self setRemoteView:self.remoteView];
//        [self.remoteView update];
//        return;
    }
    if (aVideoView == self.bigView) {
        self.bigView = nil;
        [self _refreshViewPos];
    } else {
        if (aVideoView.model.enableVideo) {
            self.bigView = aVideoView;
            [self _refreshViewPos];
        }
    }
}

- (void)miniAction
{
    self.isMini = YES;
    [super miniAction];
    // TODO:
//    self.floatingView.model.enableVideo = NO;
//    self.floatingView.delegate = self;
//    if (self.isJoined) {
//        self.floatingView.showUsername = EaseCallLocalizableString(@"Call in progress",nil);
//    } else {
//        self.floatingView.showUsername = EaseCallLocalizableString(@"waitforanswer",nil);
//    }
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

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _allUserList.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    EaseCallStreamViewModel *model = _allUserList[indexPath.item];
    EaseCallStreamView *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    cell.model = model;
    if (self.callType == EaseCallTypeMulti) {
        if (model.uid == 0) {
            [EaseCallManager.sharedManager setupLocalVideo:cell.displayView];
        } else {
            [EaseCallManager.sharedManager muteRemoteVideoStream:model.uid mute:NO];
            [EaseCallManager.sharedManager setupRemoteVideoView:model.uid withDisplayView:cell.displayView];
        }
    }
    cell.delegate = self;
    [cell update];
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

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
}

@end
