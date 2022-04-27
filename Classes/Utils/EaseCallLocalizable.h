//
//  EaseCallLocalizable.h
//  Pods
//
//  Created by lixiaoming on 2021/12/9.
//

#ifndef EaseCallLocalizable_h
#define EaseCallLocalizable_h

#import "NSBundle+AgoraChatCallKit.h"

#define EaseCallLocalizableString(key, comment)\
NSLocalizedStringFromTableInBundle(key, nil, NSBundle.agoraChatCallKitBundle, comment)

#endif /* EaseCallLocalizable_h */
