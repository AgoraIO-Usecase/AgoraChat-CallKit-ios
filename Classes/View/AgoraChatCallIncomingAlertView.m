//
//  AgoraChatCallIncomingAlertView.m
//  AgoraChatCallKit
//
//  Created by 冯钊 on 2022/4/28.
//

#import "AgoraChatCallIncomingAlertView.h"

#import <Masonry/Masonry.h>
#import "UIImage+Ext.h"

@interface AgoraChatCallIncomingAlertView ()

@property (nonatomic, copy) void(^tapHandle)(void);
@property (nonatomic, copy) void(^answerHandle)(void);
@property (nonatomic, copy) void(^hangupHandle)(void);

@end

@implementation AgoraChatCallIncomingAlertView

- (instancetype)initWithTitle:(NSString *)title content:(nonnull NSString *)content tapHandle:(nonnull void (^)(void))tapHandle answerHandle:(nonnull void (^)(void))answerHandle hangupHandle:(nonnull void (^)(void))hangupHandle
{
    if (self = [super init]) {
        _tapHandle = tapHandle;
        _answerHandle = answerHandle;
        _hangupHandle = hangupHandle;
        
        self.layer.masksToBounds = YES;
        self.layer.cornerRadius = 14;
        
        UIBlurEffect *effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
        UIVisualEffectView *effectView = [[UIVisualEffectView alloc] initWithEffect:effect];
        [self addSubview:effectView];
        
        UIButton *bgButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [bgButton addTarget:self action:@selector(bgButtonClick) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:bgButton];
        
        UILabel *titleLabel = [[UILabel alloc] init];
        titleLabel.text = title;
        titleLabel.font = [UIFont systemFontOfSize:22];
        titleLabel.textColor = UIColor.whiteColor;
        [self addSubview:titleLabel];
        
        UIImageView *iconImageView = [[UIImageView alloc] init];
        iconImageView.image = [UIImage agoraChatCallKit_imageNamed:@"alert_icon"];
        [self addSubview:iconImageView];
        
        UILabel *contentLabel = [[UILabel alloc] init];
        contentLabel.text = content;
        contentLabel.font = [UIFont systemFontOfSize:14];
        contentLabel.textColor = [UIColor colorWithWhite:1 alpha:0.6];
        [self addSubview:contentLabel];
        
        UIButton *answerButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [answerButton setImage:[UIImage agoraChatCallKit_imageNamed:@"alert_answer"] forState:UIControlStateNormal];
        [answerButton addTarget:self action:@selector(answerButtonClick) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:answerButton];
        
        UIButton *hangupButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [hangupButton setImage:[UIImage agoraChatCallKit_imageNamed:@"alert_hangup"] forState:UIControlStateNormal];
        [hangupButton addTarget:self action:@selector(hangupButtonClick) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:hangupButton];
        
        [bgButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(@0);
        }];
        
        [effectView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(@0);
        }];
        
        [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(@20);
            make.top.equalTo(@31);
        }];
        
        [iconImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(titleLabel);
            make.top.equalTo(titleLabel.mas_bottom).offset(4);
            make.width.height.equalTo(@13);
        }];
        
        [contentLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(iconImageView.mas_right).offset(5);
            make.centerY.equalTo(iconImageView);
        }];
        
        [answerButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(@-16);
            make.width.height.equalTo(@41);
            make.centerY.equalTo(self);
        }];
        
        [hangupButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(@-74);
            make.width.height.equalTo(@41);
            make.centerY.equalTo(self);
        }];
    }
    return self;
}

- (void)bgButtonClick
{
    if (_tapHandle) {
        _tapHandle();
    }
}

- (void)answerButtonClick
{
    if (_answerHandle) {
        _answerHandle();
    }
}

- (void)hangupButtonClick
{
    if (_hangupHandle) {
        _hangupHandle();
    }
}

@end
