//
//  AgoraChatCallError.m
//  EaseIM
//
//  Created by lixiaoming on 2021/1/29.
//  Copyright © 2021 lixiaoming. All rights reserved.
//

#import "AgoraChatCallError.h"

@implementation AgoraChatCallError
+(instancetype)errorWithType:(AgoarChatCallErrorType)aType code:(NSInteger)aErrCode description:(NSString*)aDescription
{
    AgoraChatCallError* error = [[AgoraChatCallError alloc] init];
    if(error) {
        error.aErrorType = aType;
        error.errCode = aErrCode;
        error.errDescription = aDescription;
    }
    return error;
}
@end
