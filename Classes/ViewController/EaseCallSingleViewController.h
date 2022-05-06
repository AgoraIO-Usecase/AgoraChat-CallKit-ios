//
//  EaseCallSingleViewController.h
//  EMiOSDemo
//
//  Created by lixiaoming on 2020/11/19.
//  Copyright © 2020 lixiaoming. All rights reserved.
//

#import "EaseCallBaseViewController.h"
#import "EaseCallStreamView.h"
#import "EaseCallManager+Private.h"

NS_ASSUME_NONNULL_BEGIN

@interface EaseCallSingleViewController : EaseCallBaseViewController

@property (nonatomic) BOOL isCaller;
@property (nonatomic) BOOL isConnected;
@property (nonatomic, copy) NSString *remoteUserAccount;

- (instancetype)initWithisCaller:(BOOL)aIsCaller type:(EaseCallType)aType  remoteName:(NSString*)aRemoteName;
- (void)setRemoteMute:(BOOL)aMuted;
- (void)setRemoteEnableVideo:(BOOL)aEnabled;
- (void)setLocalDisplayView:(UIView*)aDisplayView enableVideo:(BOOL)aEnableVideo;
- (void)setRemoteDisplayView:(UIView*)aDisplayView enableVideo:(BOOL)aEnableVideo;

@end

NS_ASSUME_NONNULL_END
