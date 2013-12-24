//
//  AppDelegate.h
//  SinglePurchaseItem
//
//  Created by Tomonori Ohba on 2013/10/16.
//
//

#import <UIKit/UIKit.h>
#import <StoreKit/StoreKit.h>

@interface AppDelegate : UIResponder
<UIApplicationDelegate,
 SKPaymentTransactionObserver> // SKPaymentTransactionObserverを追加

@property (strong, nonatomic) UIWindow *window;

@end
