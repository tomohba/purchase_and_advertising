//
//  AppDelegate.h
//  iAd-Purchase
//
//  Created by Tomonori Ohba on 2013/11/12.
//  Copyright (c) 2013年 Purchase and Advertising. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <StoreKit/StoreKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate,
SKPaymentTransactionObserver> // SKPaymentTransactionObserverを追加>

@property (strong, nonatomic) UIWindow *window;

@end
