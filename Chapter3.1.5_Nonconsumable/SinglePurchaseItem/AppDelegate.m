//
//  AppDelegate.m
//  SinglePurchaseItem
//
//  Created by Tomonori Ohba on 2013/10/16.
//
//

#import "AppDelegate.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	// updatedTransactionsを受け取るための登録
	[[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    
	return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
	// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
	// Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
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
	// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
	// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
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
				[[NSUserDefaults standardUserDefaults] setBool:YES
				                                        forKey:transaction.payment.productIdentifier];
				[[NSUserDefaults standardUserDefaults] synchronize];
                
				// 購入処理成功したことを通知する
				[[NSNotificationCenter defaultCenter] postNotificationName:@"Purchased"
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
				NSString *errormsg = [NSString stringWithFormat:@"%@ [%ld]", error.localizedDescription, (long)error.code];
				[[[UIAlertView alloc] initWithTitle:@"エラー"
				                            message:errormsg
				                           delegate:nil
				                  cancelButtonTitle:@"OK"
				                  otherButtonTitles:nil] show];
                
				// エラーの詳細
				// 支払いがキャンセルされた
				if (transaction.error.code != SKErrorPaymentCancelled) {
					NSLog(@"SKPaymentTransactionStateFailed - SKErrorPaymentCancelled");
				}
				// 請求先情報の入力画面に移り、購入処理が強制終了した
				else if (transaction.error.code == SKErrorUnknown) {
					NSLog(@"SKPaymentTransactionStateFailed - SKErrorUnknown");
				}
				// その他エラー
				else {
					NSLog(@"SKPaymentTransactionStateFailed - error.code:%ld",
					      (long)transaction.error.code);
				}
				break;
			}
                
			case SKPaymentTransactionStateRestored:
			{
				NSLog(@"SKPaymentTransactionStateRestored");
				// リストア処理完了
				// ここに購入完了時の処理を追加する
				// 設定にプロダクトIDを保持
				[[NSUserDefaults standardUserDefaults] setBool:YES
				                                        forKey:transaction.payment.productIdentifier];
				[[NSUserDefaults standardUserDefaults] synchronize];
                
				// リストアが成功したこと（＝購入成功）を通知する
				[[NSNotificationCenter defaultCenter] postNotificationName:@"Purchased"
				                                                    object:transaction];
                
				[queue finishTransaction:transaction];
				break;
			}
                
			default:
				break;
		}
	}
}

@end
