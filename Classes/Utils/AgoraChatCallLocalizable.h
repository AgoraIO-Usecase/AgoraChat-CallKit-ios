//
//  AgoraChatCallLocalizable.h
//  Pods
//
//  Created by lixiaoming on 2021/12/9.
//

#ifndef AgoraChatCallLocalizable_h
#define AgoraChatCallLocalizable_h

#import "NSBundle+AgoraChatCallKit.h"

#define AgoraChatCallLocalizableString(key, comment)\
NSLocalizedStringFromTableInBundle(key, nil, NSBundle.agoraChatCallKitBundle, comment)

#endif /* AgoraChatCallLocalizable_h */
