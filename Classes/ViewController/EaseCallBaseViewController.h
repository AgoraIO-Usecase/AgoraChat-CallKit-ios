//
//  EaseCallBaseViewController.h
//  EMiOSDemo
//
//  Created by lixiaoming on 2020/11/19.
//  Copyright © 2020 lixiaoming. All rights reserved.
//

@import UIKit;
@import AgoraChat;
#import "EaseCallDefine.h"


NS_ASSUME_NONNULL_BEGIN

@interface EaseCallBaseViewController : UIViewController

@property (nonatomic, strong) UIView *buttonView;
@property (nonatomic,strong) UIButton* microphoneButton;
@property (nonatomic,strong) UIButton* enableCameraButton;
@property (nonatomic,strong) UIButton* switchCameraButton;
@property (nonatomic,strong) UIButton* speakerButton;
@property (nonatomic,strong) UIButton* hangupButton;
@property (nonatomic,strong) UIButton* answerButton;
@property (nonatomic,strong) UILabel* timeLabel;
@property (strong, nonatomic) NSTimer *timeTimer;
@property (nonatomic, assign) int timeLength;
@property (nonatomic,strong) UIButton* miniButton;
@property (nonatomic,strong) UIImageView* bgImageView;
@property (nonatomic,strong) UIView* contentView;
@property (nonatomic) BOOL isMini;
@property (nonatomic, assign) EaseCallType callType;

- (void)hangupAction;
- (void)muteAction;
- (void)enableVideoAction;
- (void)startTimer;
- (void)answerAction;
- (void)miniAction;
- (void)usersInfoUpdated;
- (void)callFinish;
- (void)callTimerDidChange:(NSUInteger)min sec:(NSUInteger)sec;

@end

NS_ASSUME_NONNULL_END
