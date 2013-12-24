//
//  AppDelegate.h
//  MultiplePurchaseItem
//
//  Created by Tomonori Ohba on 2013/10/31.
//  Copyright (c) 2013年 Purchase and Advertising. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <StoreKit/StoreKit.h>

@interface AppDelegate : UIResponder
<UIApplicationDelegate
,SKPaymentTransactionObserver>

@property (strong, nonatomic) UIWindow *window;

@end
