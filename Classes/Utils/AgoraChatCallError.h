//
//  AgoraChatCallError.h
//  EaseIM
//
//  Created by lixiaoming on 2021/1/29.
//  Copyright © 2021 lixiaoming. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AgoraChatCallDefine.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  \~chinese
 *  `EaseCallKit` 错误类。
 *
 *  \~english
 *  The error class of `EaseCallKit`.
 */
@interface AgoraChatCallError : NSObject
/**
 *  \~chinese
 * 错误类型：
 * - Chat 错误；
 * - RTC 错误；
 * - 业务逻辑错误。
 *
 *  \~english
 *  The error type:
 *  - The Chat error.
 *  - The RTC error.
 *  - The business logic error.
 *
 */
@property (nonatomic) AgoarChatCallErrorType aErrorType;
/**
 *  \~chinese
 *  错误 ID。
 *
 *  \~english
 *  The error ID.
 */
@property (nonatomic) NSInteger errCode;
/**
 *  \~chinese
 *  错误信息。
 *
 *  \~english
 *  The error information.
 */
@property (nonatomic) NSString *errDescription;

+ (instancetype)errorWithType:(AgoarChatCallErrorType)aType code:(NSInteger)errCode description:(NSString*)aDescription;

@end

NS_ASSUME_NONNULL_END
