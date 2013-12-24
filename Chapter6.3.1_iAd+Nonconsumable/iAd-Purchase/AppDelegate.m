//
//  AppDelegate.m
//  iAd-Purchase
//
//  Created by Tomonori Ohba on 2013/11/12.
//  Copyright (c) 2013年 Purchase and Advertising. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

- (BOOL)              application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // updatedTransactionsを受け取るための登録
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // updatedTransactionsを受け取るための登録
    [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // updatedTransactionsの解除
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
}

- (void)applicationWillTerminate:(UIApplication *)application {
}

// StoreKit
// 購入、リストアなどのトランザクションの都度、通知される
- (void)   paymentQueue:(SKPaymentQueue *)queue
    updatedTransactions:(NSArray *)transactions {
    NSLog(@"paymentQueue:updatedTransactions");
    for (SKPaymentTransaction *transaction in transactions) {
        switch (transaction.transactionState) {
            // 購入処理中
            case SKPaymentTransactionStatePurchasing:
            {
                NSLog(@"SKPaymentTransactionStatePurchasing");
                break;
            }
                
            // 購入処理完了
            case SKPaymentTransactionStatePurchased:
            {
                NSLog(@"SKPaymentTransactionStatePurchased");
                // ここに購入完了時の処理を追加する
                // 設定にプロダクトIDを保持
                NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
                [ud setBool:YES
                     forKey:transaction.payment.productIdentifier];
                [ud synchronize];
                
                // 購入処理成功したことを通知する
                [[NSNotificationCenter defaultCenter]
                 postNotificationName:@"Purchased"
                 object:transaction];
                
                [queue finishTransaction:transaction];
                break;
            }
                
            // 購入処理エラー
            // ユーザが購入処理をキャンセルした場合も含む
            case SKPaymentTransactionStateFailed:
            {
                NSLog(@"SKPaymentTransactionStateFailed");
                [queue finishTransaction:transaction];
                
                // エラーメッセージを表示
                NSError *error = transaction.error;
                NSString *errormsg =
                [NSString stringWithFormat:@"%@ [%ld]",
                 error.localizedDescription, error.code];
                [[[UIAlertView alloc] initWithTitle:@"エラー"
                                            message:errormsg
                                           delegate:nil
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil] show];
                
                // エラーの詳細
                // 支払いがキャンセルされた
                if (transaction.error.code != SKErrorPaymentCancelled) {
                    NSLog(@"SKPaymentTransactionStateFailed -"
                          "SKErrorPaymentCancelled");
                }
                // 請求先情報の入力画面に移り、購入処理が強制終了した
                else if (transaction.error.code == SKErrorUnknown) {
                    NSLog(@"SKPaymentTransactionStateFailed -"
                          "SKErrorUnknown");
                }
                // その他エラー
                else {
                    NSLog(@"SKPaymentTransactionStateFailed -"
                          "error.code:%ld",
                          transaction.error.code);
                }
                
                // 購入処理エラーを通知する
                [[NSNotificationCenter defaultCenter]
                 postNotificationName:@"Failed"
                 object:transaction];
                
                break;
            }
                
            case SKPaymentTransactionStateRestored:
            {
                NSLog(@"SKPaymentTransactionStateRestored");
                // リストア処理完了
                // ここに購入完了時の処理を追加する
                // 設定にプロダクトIDを保持
                NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
                [ud setBool:YES
                     forKey:transaction.payment.productIdentifier];
                [ud synchronize];
                
                // リストアが成功したこと（＝購入成功）を通知する
                [[NSNotificationCenter defaultCenter]
                 postNotificationName:@"Restored"
                 object:transaction];
                
                [queue finishTransaction:transaction];
                break;
            }
                
            default:
                break;
        }
    }
}

// 購入処理の終了
- (void)paymentQueue:(SKPaymentQueue *)queue
 removedTransactions:(NSArray *)transactions {
    NSLog(@"paymentQueue:removedTransactions");
    
    // 購入処理が全て成功したことを通知する
    [[NSNotificationCenter defaultCenter]
     postNotificationName:@"PurchaseCompleted"
     object:transactions];
}

- (void)paymentQueueRestoreCompletedTransactionsFinished:
(SKPaymentQueue *)queue {
    // 全てのリストア処理が終了
    NSLog(@"paymentQueueRestoreCompletedTransactionsFinished");
    
    // 全てのリストア処理が終了したことを通知する
    [[NSNotificationCenter defaultCenter]
     postNotificationName:@"RestoreCompleted"
     object:queue];
}

- (void)paymentQueue:(SKPaymentQueue *)queue
    restoreCompletedTransactionsFailedWithError:(NSError *)error {
    // リストアの失敗
    NSLog(@"restoreCompletedTransactionsFailedWithError %@ [%ld]",
          error.localizedDescription, error.code);
    
    // リストアが失敗したことを通知する
    [[NSNotificationCenter defaultCenter]
     postNotificationName:@"RestoreFailed"
     object:error];
}

@end
